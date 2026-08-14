"""
End-to-end tests for files/gnome-mimeapps/generate.py.

The script is module-level (argparse → Gio.AppInfo scan → sort → write), so
these tests run it as a subprocess with the gi/Gio modules mocked (no display
server), a temp quirks file, and a temp output path — then assert on the
generated mimeapps.list.

Covers: skip_apps filtering, incubating sort priority, override application
(single/list/empty), the '#OVERRIDE ... WAS ...' tracking comment, and the
reproducible alphabetical ordering.
"""

import os
import subprocess
import sys
import textwrap

import pytest

SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "../../files/gnome-mimeapps/generate.py"))


class FakeApp:
    """Fake Gio.AppInfo with id + supported MIME types."""

    def __init__(self, app_id, types):
        self._id = app_id
        self._types = types

    def get_id(self):
        return self._id

    def get_supported_types(self):
        return list(self._types)


def _run_generate(tmp_path, quirks_toml, apps):
    quirks = tmp_path / "quirks.toml"
    quirks.write_text(textwrap.dedent(quirks_toml))
    out = tmp_path / "mimeapps.list"

    # Drive the script as a subprocess so module-level execution is real.
    code = f"""
import sys, types
from unittest.mock import MagicMock

gi = types.ModuleType('gi')
gi.require_version = MagicMock()
grep = types.ModuleType('gi.repository')
grep.Gio = MagicMock()
appdata = {[a.__dict__ for a in apps]!r}
class FakeApp:
    def __init__(self, d):
        self._d = d
    def get_id(self):
        return self._d['_id']
    def get_supported_types(self):
        return self._d['_types']
grep.Gio.AppInfo.get_all = staticmethod(lambda: [FakeApp(d) for d in appdata])
sys.modules['gi'] = gi
sys.modules['gi.repository'] = grep
sys.argv = ['generate.py', {str(quirks)!r}, {str(out)!r}]
exec(open({SCRIPT!r}).read())
"""
    result = subprocess.run(
        [sys.executable, "-c", code],
        capture_output=True, text=True, cwd=tmp_path,
    )
    if result.returncode != 0:
        pytest.fail(f"generate.py failed:\n{result.stderr}")
    return out.read_text() if out.exists() else ""


BASIC_QUIRKS = """
heading = "Generated mimeapps.list"

datadirs = [
    "/usr/share"
]

skip_apps = [
]

[incubating]

[override]
"""


def _with_override(quirks, body):
    """Insert override entries inside the existing [override] section."""
    return quirks.replace("[override]\n", "[override]\n" + body)


def _with_incubating(quirks, body):
    """Insert incubating entries inside the existing [incubating] section."""
    return quirks.replace("[incubating]\n", "[incubating]\n" + body)


class TestSkipApps:
    def test_skipped_app_excluded(self, tmp_path):
        apps = [
            FakeApp("org.gnome.Nautilus.desktop", ["inode/directory"]),
            FakeApp("org.gnome.gedit.desktop", ["text/plain"]),
        ]
        quirks = BASIC_QUIRKS.replace(
            "skip_apps = [\n]",
            'skip_apps = [\n    "org.gnome.gedit",\n]',
        )
        out = _run_generate(tmp_path, quirks, apps)
        assert "inode/directory=org.gnome.Nautilus.desktop" in out
        assert "text/plain" not in out


class TestAlphabeticalOrder:
    def test_output_sorted(self, tmp_path):
        apps = [
            FakeApp("zz.desktop", ["text/x-z"]),
            FakeApp("aa.desktop", ["text/x-a"]),
            FakeApp("mm.desktop", ["text/x-m"]),
        ]
        out = _run_generate(tmp_path, BASIC_QUIRKS, apps)
        assert 'text/x-a=aa.desktop' in out
        assert 'text/x-m=mm.desktop' in out
        assert 'text/x-z=zz.desktop' in out
        lines = [l for l in out.splitlines() if "=" in l and not l.startswith("#OVERRIDE")]
        assert lines == sorted(lines)


class TestIncubating:
    def test_incubator_replaces_core_app(self, tmp_path):
        apps = [
            # 'incubating': {'org.gnome.mynewapp': 'org.gnome.coreapp'} →
            # mynewapp gets priority (appears earlier) over coreapp.
            FakeApp("org.gnome.coreapp.desktop", ["text/plain"]),
            FakeApp("org.gnome.mynewapp.desktop", ["text/plain"]),
        ]
        quirks = _with_incubating(
            BASIC_QUIRKS, '"org.gnome.mynewapp" = "org.gnome.coreapp"\n')
        out = _run_generate(tmp_path, quirks, apps)
        line = [l for l in out.splitlines() if l.startswith("text/plain=")][0]
        apps_list = line.split("=", 1)[1].split(";")
        assert apps_list.index("org.gnome.mynewapp.desktop") < \
            apps_list.index("org.gnome.coreapp.desktop"), line

    def test_incubator_without_core_unaffected(self, tmp_path):
        apps = [
            FakeApp("org.gnome.mynewapp.desktop", ["text/plain"]),
            FakeApp("org.gnome.other.desktop", ["text/plain"]),
        ]
        quirks = _with_incubating(
            BASIC_QUIRKS, '"org.gnome.mynewapp" = "org.gnome.coreapp"\n')
        out = _run_generate(tmp_path, quirks, apps)
        line = [l for l in out.splitlines() if l.startswith("text/plain=")][0]
        apps_list = line.split("=", 1)[1].split(";")
        # mynewapp and other are unrelated → alphabetical order (mynewapp first).
        assert apps_list == sorted(apps_list)


class TestOverrides:
    def test_single_override(self, tmp_path):
        apps = [FakeApp("old.desktop", ["text/plain"])]
        quirks = _with_override(BASIC_QUIRKS, '"text/plain" = "newapp"\n')
        out = _run_generate(tmp_path, quirks, apps)
        # old.desktop must be replaced, not appended
        line = [l for l in out.splitlines() if l.startswith("text/plain=")][0]
        assert line == "text/plain=newapp.desktop"

    def test_list_override(self, tmp_path):
        apps = [FakeApp("old.desktop", ["text/plain"])]
        quirks = _with_override(BASIC_QUIRKS, '"text/plain" = ["a", "b"]\n')
        out = _run_generate(tmp_path, quirks, apps)
        assert "text/plain=a.desktop;b.desktop" in out

    def test_empty_override_removes_type(self, tmp_path):
        apps = [FakeApp("old.desktop", ["text/plain"])]
        quirks = _with_override(BASIC_QUIRKS, '"text/plain" = []\n')
        out = _run_generate(tmp_path, quirks, apps)
        assert "text/plain=" not in out

    def test_override_tracking_comment(self, tmp_path):
        apps = [FakeApp("old.desktop", ["text/plain"])]
        quirks = _with_override(BASIC_QUIRKS, '"text/plain" = "newapp"\n')
        out = _run_generate(tmp_path, quirks, apps)
        assert "#OVERRIDE text/plain WAS old.desktop" in out

    def test_override_of_missing_type_tracks_none(self, tmp_path):
        apps = [FakeApp("other.desktop", ["image/png"])]
        quirks = _with_override(BASIC_QUIRKS, '"text/plain" = "newapp"\n')
        out = _run_generate(tmp_path, quirks, apps)
        assert "#OVERRIDE text/plain WAS <none>" in out


class TestHeading:
    def test_heading_printed_stripped(self, tmp_path):
        out = _run_generate(tmp_path, BASIC_QUIRKS, [])
        assert out.startswith("Generated mimeapps.list\n")
