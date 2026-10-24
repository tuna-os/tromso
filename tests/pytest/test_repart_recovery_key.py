"""Regression tests for repart recovery key generation and gate (tuna-os/tromso#272).

Ensures gen-recovery-key.sh does not emit a hardcoded placeholder recovery
passphrase, generates cryptographic random keys with strict file permissions,
and that 50-repart defaults to an opt-in gate (INITRD_MODE:-oci != sysupdate).
"""

import os
import re
import stat
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULE_DIR = REPO / "files" / "kde-linux-system" / "generate-initramfs" / "modules" / "50-repart"
GEN_KEY_SH = MODULE_DIR / "gen-recovery-key.sh"
MODULE_SH = MODULE_DIR / "module.sh"


def test_no_hardcoded_recovery_key_in_tracked_files():
    """No tracked file should contain the upstream placeholder key."""
    out = subprocess.run(
        ["git", "-C", str(REPO), "ls-files", "-z"],
        capture_output=True,
        check=True,
        text=True,
    ).stdout
    tracked = [p for p in out.split("\0") if p]

    for rel in tracked:
        path = REPO / rel
        if not path.is_file():
            continue
        # Read text, ignoring decoding errors for binaries
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        assert "ihavenotsetarecoverykey" not in content, (
            f"Hardcoded recovery passphrase found in {rel}"
        )


def test_gen_recovery_key_stdout():
    """Running gen-recovery-key.sh prints a valid, random 55-char base32 key."""
    res1 = subprocess.run(
        [str(GEN_KEY_SH)],
        capture_output=True,
        check=True,
        text=True,
    )
    key1 = res1.stdout
    assert len(key1) == 55, f"Unexpected key length {len(key1)}: {key1!r}"
    assert re.match(r"^[A-Z2-7=]{55}$", key1), f"Unexpected key format: {key1!r}"

    res2 = subprocess.run(
        [str(GEN_KEY_SH)],
        capture_output=True,
        check=True,
        text=True,
    )
    key2 = res2.stdout
    assert len(key2) == 55
    # Successive calls must generate different random keys
    assert key1 != key2, "Two successive calls produced identical recovery keys"


def test_gen_recovery_key_to_file():
    """Running gen-recovery-key.sh with an argument creates the file with 0600 mode."""
    with tempfile.TemporaryDirectory() as tmpdir:
        target = Path(tmpdir) / "recovery-password"
        subprocess.run(
            [str(GEN_KEY_SH), str(target)],
            check=True,
        )
        assert target.is_file(), "Recovery key file was not created"
        mode = stat.S_IMODE(target.stat().st_mode)
        assert mode == 0o600, f"Expected permissions 0600, got {oct(mode)}"
        content = target.read_text()
        assert len(content) == 55
        assert re.match(r"^[A-Z2-7=]{55}$", content)


def test_repart_module_gate_opt_in():
    """50-repart module.sh must fail-closed / opt-in using ${INITRD_MODE:-oci}."""
    content = MODULE_SH.read_text()
    assert '${INITRD_MODE:-oci}' in content or '"${INITRD_MODE:-oci}"' in content, (
        "50-repart module.sh must default INITRD_MODE to oci"
    )
    # The default sysupdate should NOT be present as an unsafe fallback
    assert "${INITRD_MODE-sysupdate}" not in content


def test_repart_module_installs_head_and_tools():
    """50-repart module.sh must install dd, basenc, touch, and head."""
    content = MODULE_SH.read_text()
    for tool in ("/usr/bin/dd", "/usr/bin/basenc", "/usr/bin/touch", "/usr/bin/head"):
        assert tool in content, f"Tool {tool} not installed in module.sh"
