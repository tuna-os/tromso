"""Unit tests for files/kde-linux-system/generate-initramfs/copy-initramfs.py.

The script closes the dependency closure for initramfs payloads: it parses
systemd units, sniffs ELF/XZ/ZSTD containers, extracts DT_NEEDED / dlopen-note
/ modinfo / PT_INTERP dependencies, resolves units/libraries/modules and copies
the closure into the target root. CI only installs pytest, so elftools and zstd
are stubbed; the resolvers and copy logic run against real temp files.
"""

import importlib.util
import io
import json
import lzma
import os
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

import pytest

_SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__),
    "../../files/kde-linux-system/generate-initramfs/copy-initramfs.py"))


# ── elftools / zstd stubs ────────────────────────────────────────────────────

class DynamicSection:
    pass


class NoteSection:
    pass


class Segment:
    def __init__(self, interp):
        self._interp = interp

    def get_interp_name(self):
        return self._interp


class Tag:
    def __init__(self, needed):
        self.needed = needed


class StubELFFile:
    def __init__(self, file):
        self._segments = []
        self._sections = {}

    def add_segment(self, interp):
        self._segments.append(Segment(interp))

    def add_section(self, name, section):
        self._sections[name] = section

    def iter_segments(self, type=None):
        if type == "PT_INTERP":
            return iter(self._segments)
        return iter(())

    def get_section_by_name(self, name):
        return self._sections.get(name)


def _install_stubs():
    if "elftools" in sys.modules:
        return

    def mk(name, **attrs):
        m = types.ModuleType(name)
        m.__path__ = []
        for k, v in attrs.items():
            setattr(m, k, v)
        sys.modules[name] = m
        return m

    e = mk("elftools")
    ee = mk("elftools.elf")
    e.elf = ee  # bind parent attrs: `import elftools.elf.dynamic` sets these
    ee.elffile = mk("elftools.elf.elffile", ELFFile=StubELFFile)
    ee.dynamic = mk("elftools.elf.dynamic", DynamicSection=DynamicSection)
    ee.sections = mk("elftools.elf.sections", NoteSection=NoteSection)
    mk("zstd", decompress=lambda b: b"zstd-decompressed-content")


class _FakeDynamic(DynamicSection):
    def __init__(self, needed):
        super().__init__()
        self._needed = needed

    def iter_tags(self, type=None):
        for n in self._needed:
            yield Tag(n)


class _FakeNotes(NoteSection):
    def __init__(self, notes):
        super().__init__()
        self._notes = notes

    def iter_notes(self):
        yield from self._notes


class _RecordingResolver:
    """Records resolve_* calls; returns canned paths."""

    def __init__(self, mapping=None, prefix="/root"):
        self.mapping = mapping or {}
        self.prefix = prefix
        self.calls = []

    def _resolve(self, name, kind):
        if isinstance(name, bytes):  # modinfo deps arrive as bytes
            name = name.decode("utf-8")
        self.calls.append((kind, name))
        return self.mapping.get(name, os.path.join(self.prefix, str(name)))

    def resolve_unit(self, name):
        return self._resolve(name, "unit")

    def resolve_exe(self, name):
        return self._resolve(name, "exe")

    def resolve_library(self, name):
        return self._resolve(name, "lib")

    def resolve_module(self, name):
        return self._resolve(name, "module")

    def resolve_firmware(self, name):
        return self._resolve(name, "firmware")


class TestCopyInitramfs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _install_stubs()
        spec = importlib.util.spec_from_file_location("copy_initramfs", _SCRIPT)
        cls.mod = importlib.util.module_from_spec(spec)
        sys.modules["copy_initramfs"] = cls.mod
        spec.loader.exec_module(cls.mod)

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = self._tmp.name

    def _write(self, rel, content, mode="w"):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, mode) as f:
            f.write(content)
        return path

    # ── parse_systemd ─────────────────────────────────────────────────────

    def test_parse_sections_and_keys(self):
        mod = self.mod
        data = mod.parse_systemd(io.StringIO(
            "[Unit]\n"
            "Description=Foo\n"
            "Wants=foo.service\n"))
        self.assertEqual(data["Unit"]["Description"], ["Foo"])
        self.assertEqual(data["Unit"]["Wants"], ["foo.service"])

    def test_parse_multiple_values_accumulate(self):
        mod = self.mod
        data = mod.parse_systemd(io.StringIO(
            "[Unit]\n"
            "Wants=foo.service\n"
            "Wants=bar.service\n"))
        self.assertEqual(data["Unit"]["Wants"], ["foo.service", "bar.service"])

    def test_parse_empty_value_resets_list(self):
        mod = self.mod
        data = mod.parse_systemd(io.StringIO(
            "[Unit]\n"
            "Wants=foo.service\n"
            "Wants=\n"))
        self.assertEqual(data["Unit"]["Wants"], [])

    @pytest.mark.xfail(
        strict=True,
        reason="copy-initramfs.py parse_systemd: line continuations crash "
               "(current_value is a str; .append() raises AttributeError) — "
               "latent bug, remove marker when fixed",
    )
    def test_parse_line_continuation(self):
        mod = self.mod
        data = mod.parse_systemd(io.StringIO(
            "[Service]\n"
            "ExecStart=/bin/echo one \\\n"
            "two three\n"))
        self.assertEqual(data["Service"]["ExecStart"],
                         ["/bin/echo one two three"])

    def test_parse_ignores_comments_and_blanks(self):
        mod = self.mod
        data = mod.parse_systemd(io.StringIO(
            "# comment\n"
            "; also comment\n"
            "\n"
            "[Unit]\n"
            "Description=x\n"))
        self.assertEqual(data["Unit"]["Description"], ["x"])

    def test_parse_raises_on_unclosed_section(self):
        mod = self.mod
        with self.assertRaises(mod.ParseError):
            mod.parse_systemd(io.StringIO("[Unit\nDescription=x\n"))

    def test_parse_raises_on_line_without_equals(self):
        mod = self.mod
        with self.assertRaises(mod.ParseError):
            mod.parse_systemd(io.StringIO("[Unit]\nNotAKeyValuePair\n"))

    # ── get_dependencies_systemd ──────────────────────────────────────────

    def test_unit_wants_extracted_and_percent_units_skipped(self):
        mod = self.mod
        resolver = _RecordingResolver()
        unit = io.StringIO(
            "[Unit]\n"
            "Wants=network.target\n"
            "Requires=multi-user.target\n"
            "Upholds=foo@%i.service\n")  # % specifier -> skipped
        deps = list(mod.get_dependencies_systemd(unit, resolver))
        self.assertIn("/root/network.target", deps)
        self.assertIn("/root/multi-user.target", deps)
        self.assertNotIn("/root/foo@%i.service", deps)

    def test_exec_start_extracted_with_prefixes_stripped(self):
        mod = self.mod
        resolver = _RecordingResolver()
        unit = io.StringIO(
            "[Service]\n"
            "ExecStart=/usr/bin/daemon --flag\n"
            "ExecStartPre=-/bin/sh -c 'true'\n"
            "ExecStop=@/usr/lib/helper\n")
        deps = list(mod.get_dependencies_systemd(unit, resolver))
        self.assertIn("/usr/bin/daemon", deps)
        # '-' and '@' prefixes are stripped before resolution
        self.assertIn("/bin/sh", deps)
        self.assertIn("/usr/lib/helper", deps)

    # ── resolvers ─────────────────────────────────────────────────────────

    def test_systemd_resolver_finds_unit(self):
        mod = self.mod
        self._write("usr/lib/systemd/system/foo.service", "[Unit]\n")
        r = mod.SystemdResolver(self.root)
        self.assertEqual(r.resolve_unit("foo.service"),
                         os.path.join(self.root, "usr/lib/systemd/system/foo.service"))

    def test_systemd_resolver_falls_back_to_template(self):
        mod = self.mod
        self._write("usr/lib/systemd/system/foo@.service", "[Unit]\n")
        r = mod.SystemdResolver(self.root)
        self.assertEqual(r.resolve_unit("foo@bar.service"),
                         os.path.join(self.root, "usr/lib/systemd/system/foo@.service"))

    def test_systemd_resolver_exe_absolute_and_relative(self):
        mod = self.mod
        r = mod.SystemdResolver(self.root)
        self.assertEqual(r.resolve_exe("/usr/bin/true"),
                         os.path.join(self.root, "usr/bin/true"))
        self.assertEqual(r.resolve_exe("true"),
                         os.path.join(self.root, "usr/bin/true"))

    def test_library_resolver_searches_libdirs_in_order(self):
        mod = self.mod
        self._write("lib/x86_64-linux-gnu/libfoo.so.1", "")
        r = mod.LibraryResolver(self.root, ["/lib/x86_64-linux-gnu",
                                            "/usr/lib/x86_64-linux-gnu"])
        self.assertEqual(
            r.resolve_library("libfoo.so.1"),
            os.path.join(self.root, "lib/x86_64-linux-gnu/libfoo.so.1"))

    def test_library_resolver_falls_back_to_first_libdir(self):
        mod = self.mod
        r = mod.LibraryResolver(self.root, ["/lib/x86_64-linux-gnu",
                                            "/usr/lib"])
        self.assertEqual(
            r.resolve_library("libmissing.so.1"),
            os.path.join(self.root, "lib/x86_64-linux-gnu/libmissing.so.1"))

    # ── container sniffing ────────────────────────────────────────────────

    def test_file_sniffing_plain_content_yields_nothing(self):
        mod = self.mod
        deps = list(mod.get_dependencies_file(
            io.BytesIO(b"just text, no magic"), _RecordingResolver(),
            _RecordingResolver()))
        self.assertEqual(deps, [])

    def test_file_sniffing_xz_container(self):
        mod = self.mod
        # lzma.compress output already begins with the XZ magic
        payload = lzma.compress(b"plain text inside xz", format=lzma.FORMAT_XZ)
        deps = list(mod.get_dependencies_file(
            io.BytesIO(payload), _RecordingResolver(), _RecordingResolver()))
        self.assertEqual(deps, [])

    def test_file_sniffing_zstd_container(self):
        mod = self.mod
        deps = list(mod.get_dependencies_file(
            io.BytesIO(b"\x28\xb5\x2f\xfd" + b"rest"), _RecordingResolver(),
            _RecordingResolver()))
        self.assertEqual(deps, [])

    # ── ELF dependency extraction (fakes passed directly) ─────────────────

    def test_libs_from_dt_needed(self):
        mod = self.mod
        resolver = _RecordingResolver()  # default prefix /root
        elf = StubELFFile(None)
        elf.add_section(".dynamic", _FakeDynamic(["libc.so.6", "libm.so.6"]))
        deps = list(mod.get_dependencies_libs(elf, resolver))
        self.assertEqual(set(deps), {"/root/libc.so.6", "/root/libm.so.6"})

    def test_interp_from_pt_interp_segment(self):
        mod = self.mod
        elf = StubELFFile(None)
        elf.add_segment("/lib64/ld-linux.so.2")
        deps = list(mod.get_dependencies_interp(elf))
        self.assertEqual(deps, ["/lib64/ld-linux.so.2"])

    def test_dlopen_note_resolves_sonames(self):
        mod = self.mod
        resolver = _RecordingResolver(
            mapping={"libfoo.so.1": os.path.join(self.root, "libfoo.so.1")})
        self._write("libfoo.so.1", "")
        elf = StubELFFile(None)
        elf.add_section(".note.dlopen", _FakeNotes([{
            "n_type": 0x407c0c0a,
            "n_name": "FDO",
            "n_desc": b'[{"feature": "foo", "soname": ["libfoo.so.1"], '
                      b'"description": "needs foo"}]',
        }]))
        deps = list(mod.get_dependencies_dlopen(elf, resolver))
        self.assertEqual(deps, [os.path.join(self.root, "libfoo.so.1")])

    def test_dlopen_note_ignored_via_env(self):
        mod = self.mod
        resolver = _RecordingResolver()
        elf = StubELFFile(None)
        elf.add_section(".note.dlopen", _FakeNotes([{
            "n_type": 0x407c0c0a,
            "n_name": "FDO",
            "n_desc": b'[{"feature": "skipme", "soname": ["libx.so.1"]}]',
        }]))
        with patch.dict(os.environ, {"DLOPEN_NOTE_IGNORE": "skipme"}):
            deps = list(mod.get_dependencies_dlopen(elf, resolver))
        self.assertEqual(deps, [])

    def test_dlopen_note_missing_feature_raises(self):
        mod = self.mod
        resolver = _RecordingResolver()
        elf = StubELFFile(None)
        elf.add_section(".note.dlopen", _FakeNotes([{
            "n_type": 0x407c0c0a,
            "n_name": "FDO",
            "n_desc": b'[{"feature": "ghost", "soname": ["libghost.so.1"], '
                      b'"description": "ghost lib"}]',
        }]))
        with self.assertRaises(mod.MissingFeature) as ctx:
            list(mod.get_dependencies_dlopen(elf, resolver))
        self.assertIn("ghost", str(ctx.exception))

    def test_modinfo_depends_and_firmware(self):
        mod = self.mod
        resolver = _RecordingResolver()  # default prefix /root
        modinfo = (b"\x00depends=virtio_net,cfg80211\x00"
                   b"firmware=rtl_nic/rtl8168f-2.fw\x00")
        elf = StubELFFile(None)
        elf.add_section(".modinfo", types.SimpleNamespace(data=lambda: modinfo))
        deps = list(mod.get_dependencies_modules(elf, resolver))
        self.assertIn("/root/virtio_net", deps)
        self.assertIn("/root/cfg80211", deps)
        self.assertIn("/root/rtl_nic/rtl8168f-2.fw", deps)

    # ── get_dependencies dispatcher ───────────────────────────────────────

    def test_dispatch_symlink_yields_resolved_target(self):
        mod = self.mod
        self._write("usr/lib/real.so", "")
        os.symlink("real.so", os.path.join(self.root, "usr/lib/link.so"))
        path = os.path.join(self.root, "usr/lib/link.so")
        deps = list(mod.get_dependencies(path, _RecordingResolver(),
                                         _RecordingResolver(),
                                         _RecordingResolver()))
        self.assertEqual(deps, [os.path.join(self.root, "usr/lib/real.so")])

    def test_dispatch_dir_yields_nothing(self):
        mod = self.mod
        path = os.path.join(self.root, "usr")
        os.makedirs(path)
        deps = list(mod.get_dependencies(path, _RecordingResolver(),
                                         _RecordingResolver(),
                                         _RecordingResolver()))
        self.assertEqual(deps, [])

    def test_dispatch_systemd_unit(self):
        mod = self.mod
        resolver = _RecordingResolver()
        path = self._write("usr/lib/systemd/system/x.service",
                           "[Unit]\nWants=other.service\n")
        deps = list(mod.get_dependencies(path, _RecordingResolver(),
                                         _RecordingResolver(), resolver))
        self.assertIn("/root/other.service", deps)

    def test_dispatch_binary_plain_content(self):
        mod = self.mod
        path = self._write("usr/bin/tool", b"plain", mode="wb")
        deps = list(mod.get_dependencies(path, _RecordingResolver(),
                                         _RecordingResolver(),
                                         _RecordingResolver()))
        self.assertEqual(deps, [])

    # ── copy logic ────────────────────────────────────────────────────────

    def test_reallinkpath_normalises(self):
        mod = self.mod
        os.makedirs(os.path.join(self.root, "a/b"))
        self.assertEqual(
            mod.reallinkpath(os.path.join(self.root, "a/../a/b")),
            os.path.join(self.root, "a/b"))

    def test_is_already_copied(self):
        mod = self.mod
        targetroot = os.path.join(self.root, "out")
        self._write("out/usr/bin/tool", "x")
        self.assertTrue(mod.is_already_copied(
            "/usr/bin/tool", "/usr/bin/tool", targetroot))
        self.assertFalse(mod.is_already_copied(
            "/usr/bin/other", "/usr/bin/other", targetroot))

    def test_copy_file(self):
        mod = self.mod
        targetroot = os.path.join(self.root, "out")
        # copy() does not create parents (main() queues dirname targets first)
        os.makedirs(os.path.join(targetroot, "usr/bin"))
        src = self._write("src/tool", "content")
        mod.copy(src, "/usr/bin/tool", targetroot)
        with open(os.path.join(targetroot, "usr/bin/tool")) as f:
            self.assertEqual(f.read(), "content")

    def test_copy_symlink(self):
        mod = self.mod
        targetroot = os.path.join(self.root, "out")
        os.makedirs(os.path.join(targetroot, "usr/bin"))
        src = self._write("src/target", "")
        os.symlink("target", src + ".link")
        mod.copy(src + ".link", "/usr/bin/link", targetroot)
        out = os.path.join(targetroot, "usr/bin/link")
        self.assertTrue(os.path.islink(out))
        self.assertEqual(os.readlink(out), "target")

    def test_copy_already_present_is_noop(self):
        mod = self.mod
        targetroot = os.path.join(self.root, "out")
        self._write("out/usr/bin/tool", "existing")
        src = self._write("src/tool", "new")
        mod.copy(src, "/usr/bin/tool", targetroot)
        with open(os.path.join(targetroot, "usr/bin/tool")) as f:
            self.assertEqual(f.read(), "existing")

    def test_copy_dir(self):
        mod = self.mod
        targetroot = os.path.join(self.root, "out")
        os.makedirs(os.path.join(targetroot, "usr/lib"))
        src = os.path.join(self.root, "src/dir")
        os.makedirs(src)
        mod.copy(src, "/usr/lib/dir", targetroot)
        self.assertTrue(os.path.isdir(os.path.join(targetroot, "usr/lib/dir")))


if __name__ == "__main__":
    unittest.main()
