"""Installed-image access defaults (tuna-os/tromso#477).

The installed image must not ship development-time remote access or a
system-wide screen-lock override. The live ISO owns its own SSH setup in
``tromso/src/configure-live.sh`` and is deliberately out of scope here.

Pure source inspection: stdlib only.
"""

import re
import textwrap
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"
FILES = REPO / "files"
SYSTEM_CONFIG = (ELEMENTS / "tromso/system-config.bst").read_text()
VM_RECIPE = (REPO / "just/disk-vm.just").read_text()
README = (REPO / "README.md").read_text()


def _heredoc(text, target):
    """Return the body of the first quoted heredoc after ``target``."""
    tail = text[text.index(target):]
    return textwrap.dedent(re.search(r"<<'EOF'\n(.*?)\n\s*EOF", tail, re.S)[1])


def test_no_element_enables_sshd():
    """The SDK preset disables sshd on a desktop unless someone enables it."""
    for element in sorted(ELEMENTS.rglob("*.bst")):
        text = element.read_text()
        assert "enable sshd.service" not in text, element
        assert "ln -sf ../sshd.service" not in text, element
    # Keep the unit and its config so `systemctl enable --now sshd` works.
    assert "/usr/lib/systemd/system/sshd.service" in SYSTEM_CONFIG
    assert "/etc/ssh/sshd_config" in SYSTEM_CONFIG
    assert "/etc/pam.d/sshd" in SYSTEM_CONFIG


def test_root_ssh_requires_a_key():
    config = _heredoc(SYSTEM_CONFIG, '/etc/ssh/sshd_config"')
    roots = re.findall(r"^PermitRootLogin\s+(\S+)", config, re.MULTILINE)
    assert roots == ["prohibit-password"], roots


def test_sshd_pam_does_not_allow_empty_passwords():
    pam = _heredoc(SYSTEM_CONFIG, "/etc/pam.d/sshd\"")
    assert "nullok" not in pam
    assert re.search(r"^auth\s+required\s+pam_unix\.so", pam, re.MULTILINE)


def test_image_does_not_turn_off_the_screen_lock():
    for element in sorted(ELEMENTS.rglob("*.bst")):
        assert "/etc/xdg/kscreenlockerrc" not in element.read_text(), element
    for path in sorted(FILES.rglob("kscreenlockerrc")):
        text = path.read_text()
        for setting in ("Autolock=false", "LockOnResume=false", "Timeout=0"):
            assert setting not in text, f"{path}: {setting}"


def test_development_vm_enables_ssh_with_a_key():
    link = "${DEPLOY2}/etc/systemd/system/multi-user.target.wants/sshd.service"
    assert link in VM_RECIPE
    assert "ln -sf /usr/lib/systemd/system/sshd.service" in VM_RECIPE
    key_block = re.search(
        r'if \[ -f "\$\{HOME\}/\.ssh/id_ed25519\.pub" \]; then(.*?)\n    fi',
        VM_RECIPE,
        re.S,
    )
    assert key_block and "exit 1" in key_block[1]


def test_readme_documents_key_based_vm_login():
    assert "ssh -p 2222 -i ~/.ssh/id_ed25519 root@localhost" in README
    assert "password: tromso" not in README
