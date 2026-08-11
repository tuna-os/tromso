"""Unit tests for plugins/collect_initial_scripts.py.

The plugin (kind: collect_initial_scripts) collects per-dependency integration
scripts declared via public data ('initial-script') into the image filesystem,
writing them as numbered, sanitised files under the configured path — it is
used by 5+ elements (initramfs, devel, usr, nvidia-runtime, codecs-extra).
`buildstream` is not installed in CI, so a minimal Element stub is injected
before the plugin is imported, and the sandbox/virtual-directory API is faked
for the assemble() assertions.
"""

import importlib.util
import os
import sys
import types
import unittest
from unittest.mock import patch


# ── minimal buildstream stub ────────────────────────────────────────────────

class _StubElement:
    """Stand-in for buildstream.Element: permissive base the plugin subclasses."""

    BST_MIN_VERSION = None

    def __init__(self, *args, **kwargs):
        pass


def _install_buildstream_stub():
    if "buildstream" in sys.modules:
        return
    mod = types.ModuleType("buildstream")
    mod.Element = _StubElement
    sys.modules["buildstream"] = mod


def _load_plugin():
    _install_buildstream_stub()
    script = os.path.abspath(os.path.join(
        os.path.dirname(__file__), "../../plugins/collect_initial_scripts.py"))
    spec = importlib.util.spec_from_file_location(
        "collect_initial_scripts", script)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["collect_initial_scripts"] = mod
    spec.loader.exec_module(mod)
    return mod


# ── node / sandbox / dependency fakes ───────────────────────────────────────

class FakeNode:
    """BuildStream node stand-in recording key access."""

    def __init__(self, values):
        self.values = dict(values)

    def validate_keys(self, keys):
        missing = [k for k in keys if k not in self.values]
        if missing:
            raise KeyError(f"node missing keys: {missing}")

    def get_str(self, key):
        return self.values[key]


class FakeFile:
    def __init__(self):
        self.content = ""

    def write(self, text):
        self.content += text

    def fileno(self):
        return 1  # unused: os.chmod is patched out in the tests

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


class FakeDir:
    """Sandbox virtual-directory stand-in; open_file returns a FakeFile."""

    def __init__(self):
        self.files = {}
        self.opened_dirs = []

    def open_directory(self, relpath, create=False):
        self.opened_dirs.append(relpath)
        return self

    def open_file(self, name, mode="w"):
        f = FakeFile()
        self.files[name] = f
        return f


class FakePublic(dict):
    """BuildStream public-data node stand-in: dict-like (supports `in`)
    with a get_scalar() accessor, matching the real node API."""

    def get_scalar(self, key):
        return self[key]


class FakeDependency:
    def __init__(self, name, public):
        self.name = name
        self.public = public

    def get_public_data(self, key):
        return self.public


def _make_element(plugin, path="/usr/lib/initramfs/scripts"):
    el = plugin.ExtractInitialScriptsElement.__new__(
        plugin.ExtractInitialScriptsElement)
    el.path = path
    el.node_subst_vars = lambda s: s
    el.dependencies = lambda: []
    return el


# ── tests ───────────────────────────────────────────────────────────────────

class TestClassSurface(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = _load_plugin()

    def test_class_attributes(self):
        el = self.mod.ExtractInitialScriptsElement
        self.assertEqual(el.BST_MIN_VERSION, "2.0")
        self.assertTrue(el.BST_FORBID_RDEPENDS)
        self.assertTrue(el.BST_FORBID_SOURCES)


class TestConfigure(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = _load_plugin()

    def test_configure_reads_path(self):
        el = self.mod.ExtractInitialScriptsElement.__new__(
            self.mod.ExtractInitialScriptsElement)
        el.configure(FakeNode({"path": "/usr/lib/initramfs"}))
        self.assertEqual(el.path, "/usr/lib/initramfs")

    def test_configure_rejects_missing_path(self):
        el = self.mod.ExtractInitialScriptsElement.__new__(
            self.mod.ExtractInitialScriptsElement)
        with self.assertRaises(KeyError):
            el.configure(FakeNode({}))

    def test_get_unique_key(self):
        el = self.mod.ExtractInitialScriptsElement.__new__(
            self.mod.ExtractInitialScriptsElement)
        el.path = "/opt/scripts"
        self.assertEqual(el.get_unique_key(), {"path": "/opt/scripts"})


class TestAssemble(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = _load_plugin()

    def setUp(self):
        self.chmods = []
        self._patch = patch.object(os, "chmod",
                                   side_effect=lambda *a, **k: self.chmods.append(a))
        self._patch.start()

    def tearDown(self):
        self._patch.stop()

    def test_writes_numbered_sanitised_scripts(self):
        el = _make_element(self.mod)
        deps = [
            FakeDependency("kde-linux-system/initramfs",
                           FakePublic({"script": "#!/bin/sh\necho initramfs"})),
            FakeDependency("gnome-desktop",
                           FakePublic({"script": "#!/bin/sh\necho desktop"})),
        ]
        el.dependencies = lambda: deps
        vdir = FakeDir()
        sandbox = type("S", (), {"get_virtual_directory": lambda self: vdir})()
        el.assemble(sandbox)

        self.assertEqual(vdir.opened_dirs, ["usr/lib/initramfs/scripts"] * 2)
        self.assertEqual(set(vdir.files), {
            "001-kde_linux_system_initramfs",
            "002-gnome_desktop",
        })
        self.assertEqual(
            vdir.files["001-kde_linux_system_initramfs"].content,
            "#!/bin/sh\necho initramfs")
        # scripts are made executable (0755)
        self.assertEqual(len(self.chmods), 2)

    def test_dependency_without_initial_script_is_skipped(self):
        el = _make_element(self.mod)
        el.dependencies = lambda: [FakeDependency("plain-dep", None)]
        vdir = FakeDir()
        sandbox = type("S", (), {"get_virtual_directory": lambda self: vdir})()
        el.assemble(sandbox)
        self.assertEqual(vdir.files, {})

    def test_dependency_without_script_key_is_skipped(self):
        el = _make_element(self.mod)
        el.dependencies = lambda: [FakeDependency("nodep", FakePublic({"other": 1}))]
        vdir = FakeDir()
        sandbox = type("S", (), {"get_virtual_directory": lambda self: vdir})()
        el.assemble(sandbox)
        self.assertEqual(vdir.files, {})

    def test_script_sanitisation_keeps_alnum_only(self):
        el = _make_element(self.mod)
        el.dependencies = lambda: [FakeDependency(
            "weird.name-v2", FakePublic({"script": "x"}))]
        vdir = FakeDir()
        sandbox = type("S", (), {"get_virtual_directory": lambda self: vdir})()
        el.assemble(sandbox)
        self.assertEqual(list(vdir.files), ["001-weird_name_v2"])

    def test_path_is_stripped_of_separators(self):
        el = _make_element(self.mod, path="/opt/scripts/")
        el.dependencies = lambda: [FakeDependency("dep", FakePublic({"script": "x"}))]
        vdir = FakeDir()
        sandbox = type("S", (), {"get_virtual_directory": lambda self: vdir})()
        el.assemble(sandbox)
        self.assertEqual(vdir.opened_dirs, ["opt/scripts"])


if __name__ == "__main__":
    unittest.main()
