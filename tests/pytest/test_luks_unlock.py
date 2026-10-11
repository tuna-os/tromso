import hashlib

# Dynamically import luks-unlock.py which has a hyphen in its name
import importlib.util
import os
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, mock_open, patch

spec = importlib.util.spec_from_file_location(
    "luks_unlock",
    os.path.abspath(os.path.join(os.path.dirname(__file__), "../../tromso/src/luks-unlock.py"))
)
luks_unlock = importlib.util.module_from_spec(spec)
sys.modules["luks_unlock"] = luks_unlock
spec.loader.exec_module(luks_unlock)


class TestLuksUnlock(unittest.TestCase):

    # ── qemu_check_serial Tests ────────────────────────────────────────────────

    @patch("builtins.open", new_callable=mock_open)
    def test_qemu_check_serial_file_not_found(self, mock_file):
        # If the file does not exist, it should return "" gracefully
        mock_file.side_effect = FileNotFoundError()
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "")

    @patch("builtins.open", new_callable=mock_open, read_data="Please enter passphrase for disk /dev/vda:")
    def test_qemu_check_serial_plymouth(self, mock_file):
        # Check that it identifies "plymouth" passphrase prompt
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "plymouth")

    @patch("builtins.open", new_callable=mock_open, read_data="[  OK  ] Started gdm.service - GNOME Display Manager.")
    def test_qemu_check_serial_gdm_started(self, mock_file):
        # Check that it identifies "gdm" when service starts
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "gdm")

    @patch("builtins.open", new_callable=mock_open, read_data="Started GNOME Display Manager.")
    def test_qemu_check_serial_gdm_display_manager(self, mock_file):
        # Check that it identifies "gdm" with alternate display manager string
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "gdm")

    @patch("builtins.open", new_callable=mock_open, read_data="\x1b[1;31m  OK  ] Started \x1b[0m\ngdm.service\n- GNOME Display…")
    def test_qemu_check_serial_gdm_with_ansi_escapes(self, mock_file):
        # Check that it strips ANSI escape codes and collapses whitespace
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "gdm")

    @patch("builtins.open", new_callable=mock_open, read_data="[  OK  ] Started gnome-initial-setup.service - GNOME Initial Setup.")
    def test_qemu_check_serial_gnome_initial_setup(self, mock_file):
        # Check that it identifies "gnome-initial-setup"
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "gnome-initial-setup")

    @patch("builtins.open", new_callable=mock_open, read_data="Entering emergency mode. Exit shell to continue.")
    def test_qemu_check_serial_emergency_mode(self, mock_file):
        # Check that it identifies "emergency"
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "emergency")

    @patch("builtins.open", new_callable=mock_open, read_data="Some other boot log lines with no markers...")
    def test_qemu_check_serial_no_marker(self, mock_file):
        # Check that it returns empty string if no markers are present
        result = luks_unlock.qemu_check_serial("dummy.log")
        self.assertEqual(result, "")

    # ── virsh_dhcp_ip Tests ────────────────────────────────────────────────────

    @patch("subprocess.run")
    def test_virsh_dhcp_ip_found(self, mock_run):
        # Mock subprocess to return lease table output
        mock_proc = MagicMock()
        mock_proc.stdout = (
            " Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID\n"
            "-------------------------------------------------------------------------------------------------------------------\n"
            " 2026-05-31 15:00:00  52:54:00:fa:12:34  ipv4      192.168.122.42/24         dakota-vm       01:52:54:00:fa:12:34\n"
        )
        mock_run.return_value = mock_proc

        result = luks_unlock.virsh_dhcp_ip("52:54:00:fa:12:34")
        self.assertEqual(result, "192.168.122.42")

        # Verify case insensitivity
        result_caps = luks_unlock.virsh_dhcp_ip("52:54:00:FA:12:34")
        self.assertEqual(result_caps, "192.168.122.42")

    @patch("subprocess.run")
    def test_virsh_dhcp_ip_not_found(self, mock_run):
        mock_proc = MagicMock()
        mock_proc.stdout = (
            " Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID\n"
            "-------------------------------------------------------------------------------------------------------------------\n"
            " 2026-05-31 15:00:00  52:54:00:fa:12:34  ipv4      192.168.122.42/24         dakota-vm       01:52:54:00:fa:12:34\n"
        )
        mock_run.return_value = mock_proc

        result = luks_unlock.virsh_dhcp_ip("00:11:22:33:44:55")
        self.assertEqual(result, "")

    # ── virsh_send_passphrase Tests ────────────────────────────────────────────

    @patch("time.sleep")  # Patch sleep so tests run instantly
    @patch("subprocess.run")
    def test_virsh_send_passphrase_valid(self, mock_run, mock_sleep):
        luks_unlock.virsh_send_passphrase("myvm", "abc-1")

        # abc-1 translates to KEY_A, KEY_B, KEY_C, KEY_MINUS, KEY_1, followed by KEY_ENTER
        expected_calls = [
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_A"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_B"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_C"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_MINUS"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_1"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_ENTER"],)
        ]

        # Extract only call arguments
        actual_calls = [call[0] for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_virsh_send_passphrase_edge_cases(self, mock_run, mock_sleep):
        # Test spaces, underscores, uppercase (skipped) and special chars (skipped)
        luks_unlock.virsh_send_passphrase("myvm", "a_B $")

        # 'a' -> KEY_A
        # '_' -> KEY_MINUS
        # 'B' -> skipped (only lowercase is mapped in key_map)
        # ' ' -> KEY_SPACE
        # '$' -> skipped
        # Always followed by KEY_ENTER
        expected_calls = [
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_A"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_MINUS"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_SPACE"],),
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_ENTER"],)
        ]
        actual_calls = [call[0] for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_virsh_send_passphrase_empty(self, mock_run, mock_sleep):
        # Empty passphrase should only send KEY_ENTER
        luks_unlock.virsh_send_passphrase("myvm", "")
        expected_calls = [
            (["virsh", "send-key", "myvm", "--codeset", "linux", "KEY_ENTER"],)
        ]
        actual_calls = [call[0] for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    # ── qemu_send_passphrase Tests ────────────────────────────────────────────

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_qemu_send_passphrase_valid(self, mock_run, mock_sleep):
        luks_unlock.qemu_send_passphrase("/tmp/sock", "abc-1")

        # abc-1 translates to keys: a, b, c, minus, 1, followed by ret
        expected_calls = [
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey a\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey b\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey c\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey minus\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey 1\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey ret\n")
        ]

        actual_calls = [(call[0][0], call[1].get("input")) for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_qemu_send_passphrase_edge_cases(self, mock_run, mock_sleep):
        # Test spaces, underscores, uppercase (skipped) and special chars (skipped)
        luks_unlock.qemu_send_passphrase("/tmp/sock", "a_B $")

        # 'a' -> a
        # '_' -> shift-minus
        # 'B' -> skipped (uppercase not in map)
        # ' ' -> spc
        # '$' -> skipped
        # Always followed by ret
        expected_calls = [
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey a\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey shift-minus\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey spc\n"),
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey ret\n")
        ]
        actual_calls = [(call[0][0], call[1].get("input")) for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_qemu_send_passphrase_empty(self, mock_run, mock_sleep):
        # Empty passphrase should only send ret
        luks_unlock.qemu_send_passphrase("/tmp/sock", "")
        expected_calls = [
            (["socat", "-", "UNIX-CONNECT:/tmp/sock"], b"sendkey ret\n")
        ]
        actual_calls = [(call[0][0], call[1].get("input")) for call in mock_run.call_args_list]
        self.assertEqual(actual_calls, expected_calls)

    # ── main() Routing Tests ───────────────────────────────────────────────────

    @patch("sys.exit")
    def test_main_no_args(self, mock_exit):
        mock_exit.side_effect = SystemExit(1)
        with patch("sys.argv", ["luks-unlock.py"]):
            with self.assertRaises(SystemExit):
                luks_unlock.main()
            mock_exit.assert_called_once_with(1)

    @patch("sys.exit")
    def test_main_invalid_mode(self, mock_exit):
        mock_exit.side_effect = SystemExit(1)
        with patch("sys.argv", ["luks-unlock.py", "invalid_mode"]):
            with self.assertRaises(SystemExit):
                luks_unlock.main()
            mock_exit.assert_called_once_with(1)

    @patch("sys.exit")
    def test_main_libvirt_insufficient_args(self, mock_exit):
        mock_exit.side_effect = SystemExit(1)
        with patch("sys.argv", ["luks-unlock.py", "libvirt", "vm-name"]):
            with self.assertRaises(SystemExit):
                luks_unlock.main()
            mock_exit.assert_called_once_with(1)

    @patch("sys.exit")
    def test_main_qemu_insufficient_args(self, mock_exit):
        mock_exit.side_effect = SystemExit(1)
        with patch("sys.argv", ["luks-unlock.py", "qemu", "/tmp/sock"]):
            with self.assertRaises(SystemExit):
                luks_unlock.main()
            mock_exit.assert_called_once_with(1)

    @patch("sys.exit")
    @patch("luks_unlock.run_libvirt")
    def test_main_libvirt_success(self, mock_run_libvirt, mock_exit):
        with patch("sys.argv", ["luks-unlock.py", "libvirt", "myvm", "pass123", "52:54:00:fa:12:34"]):
            luks_unlock.main()
            mock_run_libvirt.assert_called_once_with("myvm", "pass123", "52:54:00:fa:12:34")
            mock_exit.assert_not_called()

    @patch("sys.exit")
    @patch("luks_unlock.run_qemu")
    def test_main_qemu_success(self, mock_run_qemu, mock_exit):
        with patch("sys.argv", ["luks-unlock.py", "qemu", "/tmp/sock", "pass123", "/tmp/serial.log"]):
            luks_unlock.main()
            mock_run_qemu.assert_called_once_with("/tmp/sock", "pass123", "/tmp/serial.log")
            mock_exit.assert_not_called()

    @patch("sys.exit")
    def test_main_wait_live_insufficient_args(self, mock_exit):
        mock_exit.side_effect = SystemExit(1)
        with patch("sys.argv", ["luks-unlock.py", "wait-live", "/tmp/sock"]):
            with self.assertRaises(SystemExit):
                luks_unlock.main()
            mock_exit.assert_called_once_with(1)

    @patch("sys.exit")
    @patch("luks_unlock.run_wait_live")
    def test_main_wait_live_success(self, mock_run_wait_live, mock_exit):
        with patch("sys.argv", ["luks-unlock.py", "wait-live", "/tmp/sock", "/tmp/screenshot.ppm"]):
            luks_unlock.main()
            mock_run_wait_live.assert_called_once_with("/tmp/sock", "/tmp/screenshot.ppm")
            mock_exit.assert_not_called()

    @patch("luks_unlock.qemu_screendump")
    @patch("time.sleep")
    @patch("shutil.copy2")
    def test_run_wait_live_success(self, mock_copy, mock_sleep, mock_screendump):
        mock_screendump.side_effect = [
            (0.1, 'a'),
            (2.0, 'b'),
            (2.0, 'b'),
            (2.0, 'b')
        ]
        luks_unlock.run_wait_live("/tmp/sock", "/tmp/screenshot.ppm")
        self.assertEqual(mock_screendump.call_count, 4)
        mock_copy.assert_called_with("/tmp/luks-live-boot-snap.ppm", "/tmp/screenshot.ppm")

    @patch("luks_unlock.qemu_screendump")
    @patch("time.sleep")
    @patch("shutil.copy2")
    def test_run_wait_live_timeout(self, mock_copy, mock_sleep, mock_screendump):
        # Always dark, or never stable
        mock_screendump.return_value = (0.1, 'a')
        with patch("time.time", side_effect=[0, 100, 200, 301]):
            luks_unlock.run_wait_live("/tmp/sock", "/tmp/screenshot.ppm")
        # Should not copy since brightness < threshold
        mock_copy.assert_not_called()

    @patch("luks_unlock.qemu_screendump")
    @patch("time.sleep")
    @patch("shutil.copy2")
    def test_run_wait_live_timeout_with_bright_frame(self, mock_copy, mock_sleep, mock_screendump):
        # Screen is bright but keeps changing hash
        mock_screendump.side_effect = [
            (2.0, 'b'),
            (2.0, 'c'),
            (2.0, 'd')
        ]
        with patch("time.time", side_effect=[0, 100, 200, 301]):
            luks_unlock.run_wait_live("/tmp/sock", "/tmp/screenshot.ppm")
        # Should copy the bright frames
        self.assertTrue(mock_copy.called)


class TestVirshScreenshotSize(unittest.TestCase):
    """virsh_screenshot_size(vm, path) → int"""

    @patch("subprocess.run")
    def test_returns_zero_when_virsh_fails(self, mock_run):
        """Non-zero virsh returncode → 0 regardless of file state."""
        mock_run.return_value = MagicMock(returncode=1)
        result = luks_unlock.virsh_screenshot_size("myvm", "/any/path.png")
        self.assertEqual(result, 0)

    @patch("os.path.getsize")
    @patch("subprocess.run")
    def test_returns_file_size_on_success(self, mock_run, mock_getsize):
        """virsh exits 0 and file exists → real byte count."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_getsize.return_value = 8192
        result = luks_unlock.virsh_screenshot_size("myvm", "/tmp/snap.png")
        self.assertEqual(result, 8192)

    @patch("os.path.getsize")
    @patch("subprocess.run")
    def test_returns_zero_when_file_absent_after_success(self, mock_run, mock_getsize):
        """virsh exits 0 but the screendump file was never written → 0."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_getsize.side_effect = OSError("file not found")
        result = luks_unlock.virsh_screenshot_size("myvm", "/tmp/snap.png")
        self.assertEqual(result, 0)

    @patch("subprocess.run")
    def test_passes_vm_name_to_virsh(self, mock_run):
        """The virsh command must include the requested VM name."""
        mock_run.return_value = MagicMock(returncode=1)
        luks_unlock.virsh_screenshot_size("target-vm-99", "/tmp/x.png")
        cmd = mock_run.call_args[0][0]
        self.assertIn("target-vm-99", cmd)

    @patch("os.path.getsize")
    @patch("subprocess.run")
    def test_zero_size_file_returns_zero(self, mock_run, mock_getsize):
        """virsh exits 0 but the screendump is an empty file → 0."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_getsize.return_value = 0
        result = luks_unlock.virsh_screenshot_size("myvm", "/tmp/snap.png")
        self.assertEqual(result, 0)


def _make_ppm(width: int = 4, height: int = 4, pixel_value: int = 0x80) -> bytes:
    """Return a minimal valid P6 PPM bytestring with uniform pixel colour."""
    header = f"P6\n{width} {height}\n255\n".encode()
    pixels = bytes([pixel_value] * (width * height * 3))
    return header + pixels


class TestQemuScreendump(unittest.TestCase):
    """qemu_screendump(sock, path) → (brightness, md5)

    socat is mocked so tests run without a live QEMU monitor socket.
    The PPM file is either pre-written (happy paths) or absent (error paths).
    """

    def _patch_subprocess_and_sleep(self):
        """Return a context manager stack that silences socat and time.sleep."""
        import contextlib
        return contextlib.ExitStack()

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_returns_minus_one_when_file_absent(self, mock_run, mock_sleep):
        """socat runs but produces no file → (-1, '')."""
        mock_run.return_value = MagicMock()
        brightness, md5 = luks_unlock.qemu_screendump(
            "/fake.sock", "/nonexistent/no_screen.ppm"
        )
        self.assertEqual(brightness, -1)
        self.assertEqual(md5, "")

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_valid_ppm_returns_positive_brightness(self, mock_run, mock_sleep):
        """A well-formed PPM with mid-grey pixels → brightness ≈ 128."""
        ppm = _make_ppm(4, 4, 0x80)
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(ppm)
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            brightness, md5 = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertGreater(brightness, 0)
            self.assertEqual(len(md5), 32)
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_all_black_ppm_returns_zero_brightness(self, mock_run, mock_sleep):
        """All-zero pixels → brightness 0.0 (Plymouth passphrase-screen heuristic)."""
        ppm = _make_ppm(4, 4, 0x00)
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(ppm)
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            brightness, _ = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(brightness, 0.0)
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_all_white_ppm_returns_max_brightness(self, mock_run, mock_sleep):
        """All-white pixels → brightness 255.0 (GDM / active desktop)."""
        ppm = _make_ppm(4, 4, 0xFF)
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(ppm)
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            brightness, _ = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(brightness, 255.0)
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_corrupt_ppm_missing_header_sentinel(self, mock_run, mock_sleep):
        """File exists but lacks the '255\\n' sentinel → (-1, '')."""
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(b"not a ppm file at all")
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            brightness, md5 = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(brightness, -1)
            self.assertEqual(md5, "")
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_empty_pixel_data_after_header(self, mock_run, mock_sleep):
        """Header present but zero pixels → (-1, '')."""
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(b"P6\n0 0\n255\n")  # valid header, empty pixel section
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            brightness, md5 = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(brightness, -1)
            self.assertEqual(md5, "")
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_md5_matches_file_content(self, mock_run, mock_sleep):
        """Returned MD5 must match hashlib.md5 of the raw file bytes."""
        ppm = _make_ppm(8, 8, 0x42)
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(ppm)
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            _, md5 = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(md5, hashlib.md5(ppm).hexdigest())
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_two_identical_screendumps_return_same_md5(self, mock_run, mock_sleep):
        """Stability detection requires identical MD5s across polls.
        Two calls with the same file must return the same hash."""
        ppm = _make_ppm(4, 4, 0xAA)
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as f:
            f.write(ppm)
            path = f.name
        try:
            mock_run.return_value = MagicMock()
            _, md5_first = luks_unlock.qemu_screendump("/fake.sock", path)
            _, md5_second = luks_unlock.qemu_screendump("/fake.sock", path)
            self.assertEqual(md5_first, md5_second)
        finally:
            os.unlink(path)

    @patch("time.sleep")
    @patch("subprocess.run")
    def test_different_content_returns_different_md5(self, mock_run, mock_sleep):
        """Changed screen content (different pixel values) must yield different hash.
        This is the invariant the Plymouth-stability loop depends on."""
        ppm_a = _make_ppm(4, 4, 0x10)
        ppm_b = _make_ppm(4, 4, 0x20)
        with (
            tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as fa,
            tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as fb,
        ):
            fa.write(ppm_a)
            fb.write(ppm_b)
            path_a, path_b = fa.name, fb.name
        try:
            mock_run.return_value = MagicMock()
            _, md5_a = luks_unlock.qemu_screendump("/fake.sock", path_a)
            _, md5_b = luks_unlock.qemu_screendump("/fake.sock", path_b)
            self.assertNotEqual(md5_a, md5_b)
        finally:
            os.unlink(path_a)
            os.unlink(path_b)


class TestQemuCheckSerialEdgeCases(unittest.TestCase):
    """Additional edge cases for qemu_check_serial not covered in TestLuksUnlock."""

    def _write(self, content: str) -> str:
        f = tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=False)
        f.write(content)
        f.close()
        return f.name

    def tearDown(self):
        # Temp files created by _write are cleaned up lazily; OS handles the rest.
        pass

    def test_empty_file_returns_empty(self):
        path = self._write("")
        try:
            self.assertEqual(luks_unlock.qemu_check_serial(path), "")
        finally:
            os.unlink(path)

    def test_emergency_takes_priority_over_plymouth(self):
        """If both markers are present, 'emergency' must win (checked first in code)."""
        path = self._write(
            "Please enter passphrase for disk sda3_crypt:\n"
            "You are in emergency mode!\n"
        )
        try:
            self.assertEqual(luks_unlock.qemu_check_serial(path), "emergency")
        finally:
            os.unlink(path)

    def test_emergency_shell_variant(self):
        path = self._write("You are in emergency shell.")
        try:
            self.assertEqual(luks_unlock.qemu_check_serial(path), "emergency")
        finally:
            os.unlink(path)

    def test_ansi_stripped_for_gnome_initial_setup(self):
        ansi_line = (
            "\x1b[32m  OK  \x1b[0m] Started "
            "\x1b[1mgnome-initial-setup\x1b[0m.service\n"
        )
        path = self._write(ansi_line)
        try:
            self.assertEqual(luks_unlock.qemu_check_serial(path), "gnome-initial-setup")
        finally:
            os.unlink(path)

    def test_unrelated_content_returns_empty(self):
        path = self._write("[ OK ] Started NetworkManager.service\n")
        try:
            self.assertEqual(luks_unlock.qemu_check_serial(path), "")
        finally:
            os.unlink(path)


class TestVirshSendPassphraseEdgeCases(unittest.TestCase):
    """Additional coverage: all-lowercase letters and all-digits have no warnings."""

    def _collect_warnings(self, passphrase: str) -> str:
        import io
        buf = io.StringIO()
        with (
            patch("subprocess.run", return_value=MagicMock()),
            patch("time.sleep"),
            patch("sys.stderr", buf),
        ):
            luks_unlock.virsh_send_passphrase("vm", passphrase)
        return buf.getvalue()

    def test_all_lowercase_ascii_no_warnings(self):
        import string
        warnings = self._collect_warnings(string.ascii_lowercase)
        self.assertNotIn("WARNING", warnings)

    def test_all_digits_no_warnings(self):
        warnings = self._collect_warnings("0123456789")
        self.assertNotIn("WARNING", warnings)

    def test_uppercase_triggers_warning(self):
        """Uppercase letters are not in the virsh key map → each emits a warning."""
        import io
        buf = io.StringIO()
        with (
            patch("subprocess.run", return_value=MagicMock()),
            patch("time.sleep"),
            patch("sys.stderr", buf),
        ):
            luks_unlock.virsh_send_passphrase("vm", "A")
        self.assertIn("WARNING", buf.getvalue())

    def test_special_chars_trigger_warning(self):
        import io
        buf = io.StringIO()
        with (
            patch("subprocess.run", return_value=MagicMock()),
            patch("time.sleep"),
            patch("sys.stderr", buf),
        ):
            luks_unlock.virsh_send_passphrase("vm", "!@#")
        self.assertIn("WARNING", buf.getvalue())


class TestQemuSendPassphraseEdgeCases(unittest.TestCase):
    """Additional coverage for qemu_send_passphrase."""

    def test_uppercase_triggers_warning(self):
        import io
        buf = io.StringIO()
        with (
            patch("subprocess.run", return_value=MagicMock()),
            patch("time.sleep"),
            patch("sys.stderr", buf),
        ):
            luks_unlock.qemu_send_passphrase("/sock", "Z")
        self.assertIn("WARNING", buf.getvalue())

    def test_underscore_and_minus_differ(self):
        """_ → shift-minus and - → minus must be distinct QEMU key names."""
        sent_minus = []
        sent_under = []

        def capture_minus(cmd, **kw):
            inp = kw.get("input", b"")
            if inp.startswith(b"sendkey "):
                sent_minus.append(inp[len(b"sendkey "):].strip().decode())
            return MagicMock()

        def capture_under(cmd, **kw):
            inp = kw.get("input", b"")
            if inp.startswith(b"sendkey "):
                sent_under.append(inp[len(b"sendkey "):].strip().decode())
            return MagicMock()

        with patch("subprocess.run", side_effect=capture_minus), patch("time.sleep"):
            luks_unlock.qemu_send_passphrase("/s", "-")
        with patch("subprocess.run", side_effect=capture_under), patch("time.sleep"):
            luks_unlock.qemu_send_passphrase("/s", "_")

        # First key (before "ret") must differ
        self.assertNotEqual(sent_minus[0], sent_under[0])


class TestRunLibvirt(unittest.TestCase):
    """run_libvirt() is covered by neither unit nor e2e tests: CI (test-luks-install.yml)
    only ever invokes qemu mode, never libvirt mode."""

    def _run(self, screenshot_sizes, dhcp_ips, expect_exit):
        import itertools
        size_iter = itertools.chain(screenshot_sizes, itertools.repeat(screenshot_sizes[-1]))
        ip_iter = itertools.chain(dhcp_ips, itertools.repeat(dhcp_ips[-1]))
        with patch("time.time", side_effect=range(100000)), \
             patch("time.sleep"), \
             patch.object(luks_unlock, "virsh_screenshot_size", side_effect=size_iter), \
             patch.object(luks_unlock, "virsh_send_passphrase") as mock_send, \
             patch.object(luks_unlock, "virsh_dhcp_ip", side_effect=ip_iter):
            with self.assertRaises(SystemExit) as cm:
                luks_unlock.run_libvirt("myvm", "hunter2", "aa:bb:cc:dd:ee:ff")
        self.assertEqual(cm.exception.code, expect_exit)
        return mock_send

    def test_run_libvirt_success(self):
        # Content appears (size > 4096), then Plymouth takes over (size <= 4096),
        # then DHCP lease appears — full success path.
        sizes = [5000, 5000, 100]
        ips = ["", "", "192.168.1.5"]
        mock_send = self._run(sizes, ips, expect_exit=0)
        mock_send.assert_called_once_with("myvm", "hunter2")

    def test_run_libvirt_plymouth_never_detected(self):
        # Screenshot size never exceeds 4096 — Plymouth takeover condition
        # never triggers before PROMPT_DEADLINE.
        with patch("time.time", side_effect=range(100000)), \
             patch("time.sleep"), \
             patch.object(luks_unlock, "virsh_screenshot_size", return_value=100), \
             patch.object(luks_unlock, "virsh_send_passphrase"):
            with self.assertRaises(SystemExit) as cm:
                luks_unlock.run_libvirt("myvm", "hunter2", "aa:bb:cc:dd:ee:ff")
        self.assertEqual(cm.exception.code, 1)

    def test_run_libvirt_no_dhcp_lease(self):
        # Passphrase sent, but DHCP lease never shows up before BOOT_DEADLINE.
        import itertools
        sizes = itertools.chain([5000, 100], itertools.repeat(100))
        with patch("time.time", side_effect=range(100000)), \
             patch("time.sleep"), \
             patch.object(luks_unlock, "virsh_screenshot_size", side_effect=sizes), \
             patch.object(luks_unlock, "virsh_send_passphrase"), \
             patch.object(luks_unlock, "virsh_dhcp_ip", return_value=""):
            with self.assertRaises(SystemExit) as cm:
                luks_unlock.run_libvirt("myvm", "hunter2", "aa:bb:cc:dd:ee:ff")
        self.assertEqual(cm.exception.code, 2)


class TestRunQemu(unittest.TestCase):
    """run_qemu()'s main polling loops (framebuffer-stability fallback path and
    post-passphrase boot-detection path) are exercised by CI end-to-end but have
    zero unit coverage — this class adds the fallback-path (no serial console)
    branches, which qemu_check_serial-based tests above cannot reach."""

    def _run(self, serial_results, screendumps, expect_exit):
        import itertools
        serial_iter = itertools.chain(serial_results, itertools.repeat(serial_results[-1]))
        screendump_iter = itertools.chain(screendumps, itertools.repeat(screendumps[-1]))
        with patch("time.time", side_effect=range(100000)), \
             patch("time.sleep"), \
             patch.object(luks_unlock, "qemu_check_serial", side_effect=serial_iter), \
             patch.object(luks_unlock, "qemu_screendump", side_effect=screendump_iter), \
             patch.object(luks_unlock, "qemu_send_passphrase") as mock_send, \
             patch("shutil.copy2"):
            with self.assertRaises(SystemExit) as cm:
                luks_unlock.run_qemu("/tmp/mon.sock", "hunter2", "/tmp/serial.log")
        self.assertEqual(cm.exception.code, expect_exit)
        return mock_send

    def test_run_qemu_framebuffer_stable_fallback(self):
        # No serial console output at all ("" forever): must fall back to
        # framebuffer brightness/hash-stability detection to find Plymouth,
        # then to brightness-based GDM/emergency detection post-passphrase.
        serials = [""] * 200
        screendumps = (
            [(0.2, "h0")]                              # not yet rendering
            + [(3.0, "h1")]                             # content appears
            + [(1.0, "h2"), (1.0, "h2"), (1.0, "h2")]   # stabilises (3x) -> Plymouth detected
            + [(2.5, "h3"), (2.5, "h4"), (2.5, "h4")]   # screen changes then re-stabilises -> success
            + [(2.5, "h4")] * 10
        )
        mock_send = self._run(serials, screendumps, expect_exit=0)
        mock_send.assert_called_once_with("/tmp/mon.sock", "hunter2")

    def test_run_qemu_framebuffer_emergency_dark(self):
        serials = [""] * 200
        screendumps = (
            [(0.2, "h0")]
            + [(3.0, "h1")]
            + [(1.0, "h2"), (1.0, "h2"), (1.0, "h2")]  # Plymouth detected via stability (3x)
            + [(0.9, "h3"), (0.9, "h4"), (0.9, "h4")]  # screen changes then re-stabilises, dark
            + [(0.9, "h4")] * 10
        )
        self._run(serials, screendumps, expect_exit=2)

    def test_run_qemu_plymouth_never_detected(self):
        # Screendump errors forever (-1, ""): never gets stable content, never
        # detects Plymouth via either serial or framebuffer before deadline.
        serials = [""] * 200
        screendumps = [(-1, "")] * 200
        self._run(serials, screendumps, expect_exit=1)

    def test_run_qemu_serial_emergency_after_passphrase(self):
        # Plymouth detected via serial immediately; after passphrase, serial
        # reports "emergency" -> issue #270 reproduced.
        serials = ["plymouth"] + ["emergency"] * 200
        screendumps = [(1.0, "h0")] * 200
        self._run(serials, screendumps, expect_exit=2)

    def test_run_qemu_boot_timeout(self):
        # Plymouth detected via serial; post-passphrase nothing ever confirms
        # boot (no gdm/g-i-s, screen never re-stabilises) -> timeout warning.
        serials = ["plymouth"] + [""] * 200
        screendumps = [(1.0, "h0")] + [(1.0, f"h{i}") for i in range(1, 200)]
        self._run(serials, screendumps, expect_exit=2)


if __name__ == "__main__":
    unittest.main()
