"""Unit tests for files/kde-linux-system/save-perms/save-perms.py.

The script walks a root and records non-default file modes and xattrs into a
JSON manifest (and can restore them) — BuildStream drops these otherwise. The
retrieve/apply module-level block runs on import, so we import via importlib
with sys.argv pointing at temp paths; os.chmod/os.setxattr are mocked so tests
never depend on filesystem xattr support or permissions.
"""

import importlib.util
import json
import os
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch

_SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__),
    "../../files/kde-linux-system/save-perms/save-perms.py"))


def _write(path, content="", mode=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    if mode is not None:
        os.chmod(path, mode)
    return path


class TestSavePerms(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = os.path.join(self._tmp.name, "root")
        os.makedirs(self.root)

    def _import(self, restore=False):
        backup = os.path.join(self._tmp.name, "perms.json")
        if restore:
            with open(backup, "w") as f:
                json.dump({}, f)
        spec = importlib.util.spec_from_file_location("save_perms", _SCRIPT)
        mod = importlib.util.module_from_spec(spec)
        old_argv = sys.argv
        argv = ["save-perms.py"]
        if restore:
            argv.append("--restore")
        argv += [backup, self.root]
        sys.argv = argv
        try:
            spec.loader.exec_module(mod)
        finally:
            sys.argv = old_argv
        return mod, backup

    # ── retrieve_one ──────────────────────────────────────────────────────

    def test_regular_file_nonstandard_mode_recorded(self):
        mod, _ = self._import()
        p = _write(os.path.join(self.root, "bin/tool"), "x", mode=0o600)
        doc = {}
        mod.retrieve_one(doc, self.root, "bin/tool")
        self.assertEqual(doc["bin/tool"]["mode"], 0o600)

    def test_regular_file_default_755_mode_omitted(self):
        mod, _ = self._import()
        p = _write(os.path.join(self.root, "bin/tool"), "x", mode=0o755)
        doc = {}
        mod.retrieve_one(doc, self.root, "bin/tool")
        self.assertNotIn("bin/tool", doc)

    def test_regular_file_default_644_mode_omitted(self):
        mod, _ = self._import()
        p = _write(os.path.join(self.root, "etc/f"), "x", mode=0o644)
        doc = {}
        mod.retrieve_one(doc, self.root, "etc/f")
        self.assertNotIn("etc/f", doc)

    def test_dir_nonstandard_mode_recorded(self):
        mod, _ = self._import()
        os.makedirs(os.path.join(self.root, "var/lib/secret"), mode=0o700)
        doc = {}
        mod.retrieve_one(doc, self.root, "var/lib/secret")
        self.assertEqual(doc["var/lib/secret"]["mode"], 0o700)

    def test_symlink_skipped(self):
        mod, _ = self._import()
        _write(os.path.join(self.root, "target"), "x")
        os.symlink("target", os.path.join(self.root, "link"))
        doc = {}
        mod.retrieve_one(doc, self.root, "link")
        self.assertNotIn("link", doc)

    def test_xattrs_recorded_as_hex(self):
        mod, _ = self._import()
        _write(os.path.join(self.root, "f"), "x", mode=0o600)
        with patch.object(os, "listxattr", return_value=["user.foo"]), \
                patch.object(os, "getxattr", return_value=b"\x01\x02"):
            doc = {}
            mod.retrieve_one(doc, self.root, "f")
        self.assertEqual(doc["f"]["attributes"], {"user.foo": "0102"})

    def test_retrieve_walks_tree(self):
        mod, _ = self._import()
        _write(os.path.join(self.root, "usr/bin/script"), "x", mode=0o750)
        _write(os.path.join(self.root, "usr/bin/normal"), "x", mode=0o755)
        doc = mod.retrieve(self.root)
        self.assertEqual(doc["usr/bin/script"]["mode"], 0o750)
        self.assertNotIn("usr/bin/normal", doc)

    # ── apply_one ─────────────────────────────────────────────────────────

    def test_apply_one_chmods(self):
        mod, _ = self._import(restore=True)
        p = _write(os.path.join(self.root, "f"), "x", mode=0o644)
        with patch.object(os, "chmod") as chmod:
            mod.apply_one({"f": {"mode": 0o600}}, self.root, "f")
        chmod.assert_called_once_with(p, 0o600, follow_symlinks=False)

    def test_apply_one_sets_xattrs(self):
        mod, _ = self._import(restore=True)
        p = _write(os.path.join(self.root, "f"), "x")
        with patch.object(os, "setxattr") as setxattr:
            mod.apply_one({"f": {"attributes": {"user.k": "0102"}}},
                          self.root, "f")
        setxattr.assert_called_once_with(
            p, "user.k", b"\x01\x02", flags=os.XATTR_CREATE,
            follow_symlinks=False)

    def test_apply_skips_symlinks(self):
        mod, _ = self._import(restore=True)
        _write(os.path.join(self.root, "target"), "x")
        os.symlink("target", os.path.join(self.root, "link"))
        with patch.object(os, "chmod") as chmod:
            mod.apply({"link": {"mode": 0o600}}, self.root)
        chmod.assert_not_called()

    # ── round trip ────────────────────────────────────────────────────────

    def test_round_trip_preserves_mode(self):
        # import with default args runs retrieve() and writes the manifest;
        # verify the JSON round-trips the captured mode.
        mod, backup = self._import()
        _write(os.path.join(self.root, "bin/tool"), "x", mode=0o750)
        # re-run retrieve after the import-time walk
        doc = mod.retrieve(self.root)
        with open(backup, "w") as f:
            json.dump(doc, f)
        with open(backup) as f:
            restored = json.load(f)
        self.assertEqual(restored["bin/tool"]["mode"], 0o750)


if __name__ == "__main__":
    unittest.main()
