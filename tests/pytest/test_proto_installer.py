"""
Unit tests for files/kde-linux-system/live/proto-installer/installer.py.

The script is a GTK4/Adw/dbus application that cannot be imported in a plain
pytest environment, so this module installs fake gi/dbus modules before
importing it via importlib, then exercises the pure logic:

- human_readable_size: the size→label formatter (pure function)
- Udisks.get_disks: the disk-validation policy (partition table,
  read-only, not partitionable, too-small/small/unknown thresholds)
- DiskRow.__init__: title/subtitle/suffix and media-icon selection
- Installer: dbus signal wiring and finished/failed callbacks
- InstallerApp: option parsing, status-page updates, recovery display

The dbus object graph is faked with a tiny in-memory store so the policy
branch selection is tested without a system bus.

Gtk/Adw classes are plain `MagicMock()` attributes, which is enough for
widgets used only as opaque handles — but subclassing a bare MagicMock
attribute (e.g. `class DiskRow(Adw.ActionRow):`) does not produce a real
class: Python's `__mro_entries__`/mock machinery silently replaces the
whole class body with another MagicMock, discarding every method actually
written in installer.py. So every Gtk/Adw base class that installer.py
subclasses is a small real class here (`_FakeWidget`), not a MagicMock,
which keeps the subclass's own `__init__`/methods real and testable while
still no-op'ing every inherited widget method via `__getattr__`.
"""

import importlib.util
import os
import sys
import types
from unittest.mock import MagicMock

import pytest

# ── fake GI/dbus environment ────────────────────────────────────────────────


class _FakeWidget:
    """Stand-in base for Gtk/Adw widget classes: a real class (so
    subclassing preserves the subclass's own methods), whose inherited
    attribute/method accesses are forwarded to a per-instance MagicMock."""

    def __init__(self, *args, **kwargs):
        object.__setattr__(self, "_calls", MagicMock())

    def __getattr__(self, name):
        return getattr(self._calls, name)

    @classmethod
    def new(cls, *args, **kwargs):
        return cls()


class _FakeTemplate:
    """Stand-in for Gtk.Template: identity decorators instead of the
    MagicMock-call chain that would otherwise erase decorated classes."""

    def __call__(self, *args, **kwargs):
        return lambda cls: cls

    Callback = staticmethod(lambda *args, **kwargs: (lambda fn: fn))
    Child = staticmethod(lambda *args, **kwargs: MagicMock())


_FAKE_GTK = MagicMock()
_FAKE_ADW = MagicMock()
_FAKE_GOBJECT = MagicMock()
_FAKE_GIO = MagicMock()
_FAKE_GLIB = MagicMock()


def _install_fake_modules():
    """Install fake gi/dbus modules so installer.py imports without a
    display server, system bus, or compiled gresource."""
    _FAKE_GTK.Template = _FakeTemplate()
    _FAKE_GTK.Button = type("Button", (_FakeWidget,), {})
    _FAKE_GTK.Box = type("Box", (_FakeWidget,), {})
    _FAKE_ADW.ActionRow = type("ActionRow", (_FakeWidget,), {})
    _FAKE_ADW.NavigationPage = type("NavigationPage", (_FakeWidget,), {})
    _FAKE_ADW.ApplicationWindow = type("ApplicationWindow", (_FakeWidget,), {})
    _FAKE_ADW.Application = type("Application", (_FakeWidget,), {})

    gi = types.ModuleType("gi")
    gi.require_version = MagicMock()
    gi_repo = types.ModuleType("gi.repository")
    for name, mod in [
        ("Gtk", _FAKE_GTK), ("Adw", _FAKE_ADW), ("GObject", _FAKE_GOBJECT),
        ("Gio", _FAKE_GIO), ("GLib", _FAKE_GLIB),
    ]:
        setattr(gi_repo, name, mod)
    sys.modules["gi"] = gi
    sys.modules["gi.repository"] = gi_repo

    dbus = types.ModuleType("dbus")
    dbus.SystemBus = MagicMock
    # A plain `MagicMock` class (not a factory) breaks when the object under
    # construction is called with a Mock as its first positional arg (e.g.
    # `dbus.Interface(some_mock_object, dbus_interface=...)`): MagicMock's
    # own first positional parameter is `spec`, and spec'ing on a Mock raises
    # InvalidSpecError. A factory sidesteps that entirely.
    dbus.Interface = lambda *args, **kwargs: MagicMock()
    dbus.PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
    dbus.mainloop = types.ModuleType("dbus.mainloop")
    dbus.mainloop.glib = types.ModuleType("dbus.mainloop.glib")
    sys.modules["dbus"] = dbus
    sys.modules["dbus.mainloop"] = dbus.mainloop
    sys.modules["dbus.mainloop.glib"] = dbus.mainloop.glib

    # Gio.Resource.load happens at module level and would hit the real
    # filesystem — neutralise it.
    _FAKE_GIO.Resource.load = staticmethod(lambda path: MagicMock())
    _FAKE_GIO.Resource._register = staticmethod(lambda r: None)
    _FAKE_GIO.Resource.register = staticmethod(lambda r: None)


_INSTALLER = None


@pytest.fixture(scope="module", autouse=True)
def _installer_module():
    global _INSTALLER
    if _INSTALLER is not None:
        return _INSTALLER
    _install_fake_modules()
    path = os.path.join(os.path.dirname(__file__),
                        "../../files/kde-linux-system/live/proto-installer/installer.py")
    spec = importlib.util.spec_from_file_location("proto_installer", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    _INSTALLER = mod
    return mod


@pytest.fixture(autouse=True)
def _reset_shared_template_children(_installer_module):
    """`Gtk.Template.Child()` widgets are assigned once as class attributes,
    so every instance of e.g. WarningIcon/ErrorIcon/StatusDisplay shares the
    same underlying MagicMock — reset call history before each test so
    assert_called_once-style checks aren't polluted by an earlier test."""
    for widget_cls in (_installer_module.WarningIcon, _installer_module.ErrorIcon,
                       _installer_module.StatusDisplay, _installer_module.DiskSelector,
                       _installer_module.InstallerWindow):
        for value in vars(widget_cls).values():
            if isinstance(value, MagicMock):
                value.reset_mock()


# ── human_readable_size ─────────────────────────────────────────────────────

class TestHumanReadableSize:
    def test_bytes(self, _installer_module):
        assert _installer_module.human_readable_size(0) == "0B"
        assert _installer_module.human_readable_size(1) == "1B"
        assert _installer_module.human_readable_size(500) == "500B"
        assert _installer_module.human_readable_size(1023) == "1023B"

    def test_kb_rounds_like_gnome_disks(self, _installer_module):
        # < 10 with a decimal, otherwise rounded integer.
        assert _installer_module.human_readable_size(2048) == "2.0KB"
        assert _installer_module.human_readable_size(10 * 1024) == "10KB"
        assert _installer_module.human_readable_size(512 * 1024) == "512KB"

    def test_mb(self, _installer_module):
        assert _installer_module.human_readable_size(1024 * 1024) == "1.0MB"
        assert _installer_module.human_readable_size(1024 * 1024 * 100) == "100MB"

    def test_gb(self, _installer_module):
        assert _installer_module.human_readable_size(1024 ** 3) == "1.0GB"
        assert _installer_module.human_readable_size(30 * 1024 ** 3) == "30GB"

    def test_tb(self, _installer_module):
        assert _installer_module.human_readable_size(1024 ** 4) == "1.0TB"
        assert _installer_module.human_readable_size(2 * 1024 ** 4) == "2.0TB"

    def test_never_returns_none_for_valid_sizes(self, _installer_module):
        for size in [0, 1, 500, 1023, 1024, 10 * 1024, 1024 ** 3,
                     30 * 1024 ** 3, 1024 ** 4, 1024 ** 5]:
            assert _installer_module.human_readable_size(size) is not None


# ── Udisks.get_disks validation policy ──────────────────────────────────────

def _make_block(properties):
    """Return a fake dbus block object whose Get() serves a property dict."""
    block = MagicMock()
    block.Get.side_effect = lambda iface, prop, **kw: properties.get(
        ("%s.%s" % (iface.split(".")[-1], prop)), properties.get(prop))
    return block


def _run_get_disks(_installer_module, blocks, drives=None, partition_tables=None):
    """Drive Udisks.get_disks through a fake dbus object manager."""
    drives = drives or {}
    partition_tables = partition_tables or {}

    class FakeObject:
        def __init__(self, path):
            self.path = path

    class FakeDrive:
        def __init__(self, model):
            self.model = model

        def Get(self, iface, prop, **kw):
            if prop == "Model":
                return self.model
            return None

        def get_model(self):
            return self.model

    objects = {}
    for path in drives:
        objects[path] = ["org.freedesktop.UDisks2.Drive"]
    for path in blocks:
        ifaces = ["org.freedesktop.UDisks2.Block"]
        if path in partition_tables:
            ifaces.append("org.freedesktop.UDisks2.PartitionTable")
        objects[path] = ifaces

    fake_iface = MagicMock()
    fake_iface.GetManagedObjects.return_value = objects

    bus = MagicMock()
    bus.get_object.side_effect = lambda svc, path: (
        FakeDrive(drives[path]) if path in drives else _make_block(blocks[path])
    )

    udisks = _installer_module.Udisks.__new__(_installer_module.Udisks)
    udisks.system_bus = bus
    udisks.manager_interface = fake_iface
    udisks.objman_interface = fake_iface
    # get_disks reads partition-table type per block via a second bus lookup;
    # emulate the block's own PartitionTable property.
    for path, ptype in partition_tables.items():
        blocks[path]["PartitionTable-Type"] = ptype

    return udisks.get_disks()


# Each block gets a fake Drive object; only drives referenced by a block matter.
def _with_drive(blocks, drive_path, model):
    return {drive_path: {"model": model}}


class TestGetDisksValidationPolicy:
    def _base_block(self, size=40 * 1024 ** 3):
        return {
            "Device": b"/dev/sda\x00",
            "Size": size,
            "ReadOnly": False,
            "HintPartitionable": True,
        }

    def test_valid_disk_has_no_invalid_flag(self, _installer_module):
        blocks = {"/org/freedesktop/UDisks2/block_devices/sda": self._base_block()}
        drives = {"/org/freedesktop/UDisks2/drives/drive0": "Test SSD"}
        # map drive path into block properties
        blocks["/org/freedesktop/UDisks2/block_devices/sda"]["Drive"] = "/org/freedesktop/UDisks2/drives/drive0"
        blocks["/org/freedesktop/UDisks2/block_devices/sda"]["MediaCompatibility"] = ["ssd"]

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert len(ret) == 1
        name, model, size, media, invalid = ret[0]
        assert name == "sda"
        assert model == "Test SSD"
        assert invalid is None, f"40GB partitionable disk should be valid, got {invalid}"

    def test_partition_table_is_error(self, _installer_module):
        blocks = {"/b/sda": self._base_block()}
        blocks["/b/sda"]["Drive"] = "/d0"
        blocks["/b/sda"]["MediaCompatibility"] = ["ssd"]
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives,
                             partition_tables={"/b/sda": "gpt"})
        name, model, size, media, invalid = ret[0]
        assert invalid is not None
        assert invalid[0] == "error"
        assert "partition table" in invalid[1]

    def test_readonly_is_error(self, _installer_module):
        blocks = {"/b/sda": self._base_block()}
        blocks["/b/sda"].update({"Drive": "/d0", "MediaCompatibility": ["ssd"], "ReadOnly": True})
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert ret[0][4] is not None and ret[0][4][0] == "error"
        assert "read-only" in ret[0][4][1].lower()

    def test_not_partitionable_is_error(self, _installer_module):
        blocks = {"/b/sda": self._base_block()}
        blocks["/b/sda"].update({"Drive": "/d0", "MediaCompatibility": ["ssd"],
                                 "HintPartitionable": False})
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert ret[0][4] is not None and ret[0][4][0] == "error"
        assert "cannot be partitioned" in ret[0][4][1].lower()

    def test_under_10gb_is_error(self, _installer_module):
        blocks = {"/b/sda": self._base_block(size=8 * 1024 ** 3)}
        blocks["/b/sda"].update({"Drive": "/d0", "MediaCompatibility": ["ssd"]})
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert ret[0][4] is not None and ret[0][4][0] == "error"
        assert "too small" in ret[0][4][1].lower()

    def test_10_to_30gb_is_warning(self, _installer_module):
        blocks = {"/b/sda": self._base_block(size=20 * 1024 ** 3)}
        blocks["/b/sda"].update({"Drive": "/d0", "MediaCompatibility": ["ssd"]})
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert ret[0][4] is not None and ret[0][4][0] == "warning"
        assert "small" in ret[0][4][1].lower()

    def test_unknown_size_is_warning(self, _installer_module):
        blocks = {"/b/sda": self._base_block(size=0)}
        blocks["/b/sda"].update({"Drive": "/d0", "MediaCompatibility": ["ssd"]})
        drives = {"/d0": "Test SSD"}

        ret = _run_get_disks(_installer_module, blocks, drives)
        assert ret[0][4] is not None and ret[0][4][0] == "warning"
        assert "unknown" in ret[0][4][1].lower()


# ── DiskRow.__init__ ─────────────────────────────────────────────────────────

class TestDiskRow:
    def test_title_and_subtitle_set_from_args(self, _installer_module):
        row = _installer_module.DiskRow("sda", "Test SSD", 40 * 1024 ** 3, ["ssd"], None)
        row.set_title.assert_called_once_with("Test SSD")
        row.set_subtitle.assert_called_once_with(
            _installer_module.human_readable_size(40 * 1024 ** 3))
        assert row.get_device_name() == "sda"

    def test_zero_size_skips_subtitle(self, _installer_module):
        row = _installer_module.DiskRow("sda", "Unknown", 0, ["ssd"], None)
        row.set_subtitle.assert_not_called()

    def test_no_invalid_flag_stays_selectable_and_adds_no_suffix(self, _installer_module):
        row = _installer_module.DiskRow("sda", "Test SSD", 40 * 1024 ** 3, ["ssd"], None)
        row.set_selectable.assert_not_called()
        row.add_suffix.assert_not_called()

    def test_warning_invalid_adds_suffix_but_stays_selectable(self, _installer_module):
        row = _installer_module.DiskRow(
            "sda", "Small disk", 20 * 1024 ** 3, ["ssd"], ("warning", "small"))
        row.set_selectable.assert_not_called()
        (suffix,), _ = row.add_suffix.call_args
        assert isinstance(suffix, _installer_module.WarningIcon)

    def test_error_invalid_marks_unselectable(self, _installer_module):
        row = _installer_module.DiskRow(
            "sda", "Bad disk", 5 * 1024 ** 3, ["ssd"], ("error", "too small"))
        row.set_selectable.assert_called_once_with(False)
        (suffix,), _ = row.add_suffix.call_args
        assert isinstance(suffix, _installer_module.ErrorIcon)

    @pytest.mark.parametrize("media, expected_icon", [
        (["flash_disk"], "media-flash-symbolic"),
        (["thumb"], "drive-harddisk-usb-symbolic"),
        (["floppy3"], "media-floppy-symbolic"),
        (["optical_cd"], "media-optical-symbolic"),
        ([], "drive-harddisk-symbolic"),
        (["unknown-media"], "drive-harddisk-symbolic"),
    ])
    def test_media_icon_selection(self, _installer_module, media, expected_icon):
        row = _installer_module.DiskRow("sda", "Disk", 40 * 1024 ** 3, media, None)
        (icon_widget,), _ = row.add_prefix.call_args
        icon_widget.set_icon_name.assert_called_once_with(expected_icon)
        icon_widget.set_has_frame.assert_called_once_with(False)
        icon_widget.set_can_target.assert_called_once_with(False)

    def test_media_first_match_wins(self, _installer_module):
        # flash checked before thumb/floppy/optical — first match in the
        # media list order should win the icon, not the first matching kind.
        row = _installer_module.DiskRow(
            "sda", "Disk", 40 * 1024 ** 3, ["thumb", "flash_disk"], None)
        (icon_widget,), _ = row.add_prefix.call_args
        icon_widget.set_icon_name.assert_called_once_with("drive-harddisk-usb-symbolic")


# ── WarningIcon / ErrorIcon ──────────────────────────────────────────────────

class TestIcons:
    def test_warning_icon_sets_markup(self, _installer_module):
        icon = _installer_module.WarningIcon("be careful")
        icon.WarningLabel.set_markup.assert_called_once_with("be careful")

    def test_error_icon_sets_markup(self, _installer_module):
        icon = _installer_module.ErrorIcon("nope")
        icon.ErrorLabel.set_markup.assert_called_once_with("nope")


# ── Installer (dbus wiring) ──────────────────────────────────────────────────

class TestInstaller:
    def test_init_wires_finished_and_failed_signals(self, _installer_module):
        on_finished = MagicMock()
        on_error = MagicMock()
        installer = _installer_module.Installer(on_finished, on_error)

        signal_names = [c.args[0] for c in installer._installer.connect_to_signal.call_args_list]
        assert "InstallationFinished" in signal_names
        assert "InstallationFailed" in signal_names

    def test_install_delegates_to_dbus_interface(self, _installer_module):
        installer = _installer_module.Installer(MagicMock(), MagicMock())
        installer._installer.Install.return_value = "recovery-key-123"

        result = installer.install("/dev/sda", True)

        installer._installer.Install.assert_called_once_with("/dev/sda", True)
        assert result == "recovery-key-123"

    def test_installation_finished_calls_on_finished(self, _installer_module):
        on_finished = MagicMock()
        installer = _installer_module.Installer(on_finished, MagicMock())

        installer._installation_finished()

        on_finished.assert_called_once_with()

    def test_installation_failed_calls_on_error_with_message(self, _installer_module):
        on_error = MagicMock()
        installer = _installer_module.Installer(MagicMock(), on_error)

        installer._installation_failed("disk full")

        on_error.assert_called_once_with("disk full")


# ── InstallerApp pure-logic methods ──────────────────────────────────────────

def _bare_app(_installer_module):
    """Construct an InstallerApp without running Adw.Application.__init__
    (which would need a real GApplication) — same __new__ bypass pattern
    already used above for Udisks."""
    app = _installer_module.InstallerApp.__new__(_installer_module.InstallerApp)
    return app


class TestInstallerAppLogic:
    def test_handle_local_options_reads_both_flags(self, _installer_module):
        app = _bare_app(_installer_module)
        option = MagicMock()
        option.lookup_value.side_effect = lambda key: {
            "oem-mode": True, "wait-for-tour-mode": None,
        }[key]

        ret = app.handle_local_options(MagicMock(), option)

        assert app.oem_mode is True
        assert app.wait_for_tour_mode is False
        assert ret == -1

    def test_on_finished_updates_status_page(self, _installer_module):
        app = _bare_app(_installer_module)
        app._status_content = MagicMock()

        app._on_finished()

        app._status_content.Spinner.set_visible.assert_called_once_with(False)
        app._status_content.StatusPage.set_icon_name.assert_called_once_with("checkmark-symbolic")
        app._status_content.StatusPage.set_description.assert_called_once()

    def test_on_error_reports_message_in_description(self, _installer_module):
        app = _bare_app(_installer_module)
        app._status_content = MagicMock()

        app._on_error("disk full")

        app._status_content.StatusPage.set_icon_name.assert_called_once_with("computer-fail-symbolic")
        (desc,), _ = app._status_content.StatusPage.set_description.call_args
        assert "disk full" in desc

    def test_disk_selected_enables_install_button(self, _installer_module):
        app = _bare_app(_installer_module)
        app._install_button = MagicMock()

        app._disk_selected(MagicMock(), MagicMock())

        app._install_button.set_can_target.assert_called_once_with(True)

    def test_display_recovery_with_key_shows_recovery_display(self, _installer_module):
        app = _bare_app(_installer_module)
        app.win = MagicMock()
        app._install_button = MagicMock()

        app.display_recovery("ABCD-1234")

        app.win.Header.remove.assert_called_once_with(app._install_button)
        assert isinstance(app._status_content, _installer_module.StatusDisplay)
        app._status_content.RecoveryKey.set_label.assert_called_once_with("ABCD-1234")
        app._status_content.RecoveryKeyDisplay.set_visible.assert_called_once_with(True)
        app.win.NavigationView.push.assert_called_once_with(app._status_content)

    def test_display_recovery_without_key_hides_recovery_display(self, _installer_module):
        app = _bare_app(_installer_module)
        app.win = MagicMock()
        app._install_button = MagicMock()

        app.display_recovery(None)

        app._status_content.RecoveryKeyDisplay.set_visible.assert_called_once_with(False)
