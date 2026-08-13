"""Unit tests for files/kde-linux-system/make-layer.py.

make-layer.py is installed as /usr/bin/make-layer in the KDE image and merges
two overlay roots (lower + upper) into an output root — it composes the devel
and nvidia-runtime layers. Per layer.bst the output root starts EMPTY and the
script emits a *delta* layer: upper's new/changed files and symlinks, plus
whiteout nodes for lower-only entries (identical files stay in the base image).

The merge loop runs at module level, so we import via importlib with sys.argv
pointing at real temp dirs and os.mknod patched (whiteout device nodes need
privileges CI doesn't have). The individual copy/compare/stat helpers are then
exercised directly.
"""

import importlib.util
import os
import shutil
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch

_SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "../../files/kde-linux-system/make-layer.py"))


def _write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    return path


class TestMakeLayer(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.lower = os.path.join(self._tmp.name, "lower")
        self.upper = os.path.join(self._tmp.name, "upper")
        self.output = os.path.join(self._tmp.name, "output")
        for d in (self.lower, self.upper, self.output):
            os.makedirs(d)

    def _run_merge(self):
        """Import make-layer.py — the module-level loop executes the merge.

        Returns (module, mknod_call_paths) where mknod_call_paths records every
        whiteout path requested (os.mknod itself is stubbed out).
        """
        mknod_calls = []
        spec = importlib.util.spec_from_file_location("make_layer", _SCRIPT)
        mod = importlib.util.module_from_spec(spec)
        old_argv = sys.argv
        sys.argv = ["make-layer.py", self.lower, self.upper, self.output]
        try:
            with patch.object(os, "mknod",
                              side_effect=lambda *a, **k: mknod_calls.append(a)):
                spec.loader.exec_module(mod)
        finally:
            sys.argv = old_argv
        return mod, mknod_calls

    # ── copy helpers ──────────────────────────────────────────────────────

    def test_copy_file_creates_parent_dirs(self):
        mod, _ = self._run_merge()
        _write(os.path.join(self.upper, "etc/a/b.conf"), "cfg")
        mod.copy_file("etc/a/b.conf")
        with open(os.path.join(self.output, "etc/a/b.conf")) as f:
            self.assertEqual(f.read(), "cfg")

    def test_copy_link_preserves_symlink(self):
        mod, _ = self._run_merge()
        os.makedirs(os.path.join(self.upper, "lib"))
        os.symlink("../etc", os.path.join(self.upper, "lib/target"))
        mod.copy_link("lib/target")
        out = os.path.join(self.output, "lib/target")
        self.assertTrue(os.path.islink(out))
        self.assertEqual(os.readlink(out), "../etc")

    def test_copy_dir(self):
        mod, _ = self._run_merge()
        os.makedirs(os.path.join(self.upper, "usr/share/foo"))
        mod.copy_dir("usr/share/foo")
        self.assertTrue(os.path.isdir(os.path.join(self.output, "usr/share/foo")))

    def test_copy_parent_dirs_reuses_existing(self):
        mod, _ = self._run_merge()
        os.makedirs(os.path.join(self.upper, "a/b"))
        os.makedirs(os.path.join(self.output, "a"))
        mod.copy_dir("a/b")
        self.assertTrue(os.path.isdir(os.path.join(self.output, "a/b")))

    # ── comparison helpers ────────────────────────────────────────────────

    def test_compare_files_identical(self):
        mod, _ = self._run_merge()
        # copy2 preserves content AND stat (mtime_ns) — compare_files requires
        # exact equality, so separately-written files would be timing-flaky.
        a = _write(os.path.join(self.lower, "f"), "same")
        b = os.path.join(self.upper, "f")
        shutil.copy2(a, b)
        self.assertTrue(mod.compare_files(a, b))

    def test_compare_files_different_content(self):
        mod, _ = self._run_merge()
        a = _write(os.path.join(self.lower, "f"), "aaa")
        b = _write(os.path.join(self.upper, "f"), "bbb")
        self.assertFalse(mod.compare_files(a, b))

    def test_compare_files_different_stat(self):
        mod, _ = self._run_merge()
        a = _write(os.path.join(self.lower, "f"), "same")
        b = _write(os.path.join(self.upper, "f"), "same")
        os.utime(a, (1000, 1000))
        os.utime(b, (2000, 2000))
        self.assertFalse(mod.compare_files(a, b))

    def test_get_stat_shape(self):
        mod, _ = self._run_merge()
        p = _write(os.path.join(self.upper, "f"), "x")
        st = mod.get_stat(p)
        self.assertEqual(len(st), 6)
        self.assertEqual(stat.S_IFMT(st[0]), stat.S_IFREG)

    # ── full merge semantics (populate first, then import runs the merge) ─

    def test_upper_new_file_appears_in_output(self):
        _write(os.path.join(self.upper, "usr/bin/tool"), "bin")
        self._run_merge()
        with open(os.path.join(self.output, "usr/bin/tool")) as f:
            self.assertEqual(f.read(), "bin")

    def test_upper_overrides_changed_lower_file(self):
        _write(os.path.join(self.lower, "etc/app.conf"), "old")
        _write(os.path.join(self.upper, "etc/app.conf"), "new")
        self._run_merge()
        with open(os.path.join(self.output, "etc/app.conf")) as f:
            self.assertEqual(f.read(), "new")

    def test_identical_file_excluded_from_delta(self):
        # Output is a delta layer: files unchanged versus lower stay in the
        # base image and must NOT be emitted again.
        a = _write(os.path.join(self.lower, "f"), "same")
        shutil.copy2(a, os.path.join(self.upper, "f"))  # identical incl. stat
        self._run_merge()
        self.assertFalse(os.path.exists(os.path.join(self.output, "f")))

    def test_lower_only_file_triggers_whiteout(self):
        # lower-only entry whose parent dir exists in upper -> whiteout node
        os.makedirs(os.path.join(self.upper, "etc"))  # parent present in upper
        _write(os.path.join(self.lower, "etc/removed.conf"), "x")
        _, mknod_calls = self._run_merge()
        self.assertTrue(
            any("removed.conf" in str(c[0]) for c in mknod_calls),
            f"expected whiteout for etc/removed.conf, got {mknod_calls}")

    def test_symlink_in_lower_replaced_by_regular_file_in_upper(self):
        _write(os.path.join(self.lower, "lib/x"), "ignored")
        os.unlink(os.path.join(self.lower, "lib/x"))
        os.symlink("/nowhere", os.path.join(self.lower, "lib/x"))
        _write(os.path.join(self.upper, "lib/x"), "real")
        self._run_merge()
        out = os.path.join(self.output, "lib/x")
        self.assertTrue(os.path.isfile(out))
        with open(out) as f:
            self.assertEqual(f.read(), "real")

    def test_upper_symlink_where_lower_has_regular_file(self):
        _write(os.path.join(self.lower, "lib/x"), "old")
        os.makedirs(os.path.join(self.upper, "lib"), exist_ok=True)
        os.symlink("/elsewhere", os.path.join(self.upper, "lib/x"))
        self._run_merge()
        out = os.path.join(self.output, "lib/x")
        self.assertTrue(os.path.islink(out))
        self.assertEqual(os.readlink(out), "/elsewhere")

    def test_upper_link_differing_from_lower_link_is_recopied(self):
        os.makedirs(os.path.join(self.lower, "lib"))
        os.symlink("/old-target", os.path.join(self.lower, "lib/x"))
        os.makedirs(os.path.join(self.upper, "lib"))
        os.symlink("/new-target", os.path.join(self.upper, "lib/x"))
        self._run_merge()
        out = os.path.join(self.output, "lib/x")
        self.assertTrue(os.path.islink(out))
        self.assertEqual(os.readlink(out), "/new-target")


if __name__ == "__main__":
    unittest.main()
