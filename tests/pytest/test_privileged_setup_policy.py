"""Guards the privileged-setup polkit action and hooks (tuna-os/tromso#269).

`/usr/bin/ublue-privileged-setup` runs every hook in the privileged hooks
directory as root. Its polkit action once authorized every subject with no
authentication, so any local account could trigger the hooks. The action must
require admin authentication, and hooks that act on behalf of the invoking
user (PKEXEC_UID) must confirm that user is an administrator.

Pure source inspection: stdlib only.
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SYSTEM_FILES = REPO / "files/tromso/aurora-common/system_files/shared/usr"
POLICY = SYSTEM_FILES / "share/polkit-1/actions/org.ublue.privileged.user.setup.policy"
TAILSCALE_HOOK = SYSTEM_FILES / "share/ublue-os/privileged-setup.hooks.d/10-tailscale.sh"


def test_privileged_setup_action_requires_authentication():
    text = POLICY.read_text()
    for key in ("allow_any", "allow_inactive", "allow_active"):
        value = re.search(rf"<{key}>([^<]*)</{key}>", text)
        assert value, f"{key} missing from {POLICY.name}"
        assert value.group(1).startswith("auth_"), (
            f"{key}={value.group(1)!r}: the root privileged-setup helper must "
            "not be authorized without authentication"
        )


def test_tailscale_hook_requires_wheel_before_operator_assignment():
    text = TAILSCALE_HOOK.read_text()
    wheel_check = text.index("wheel")
    assert wheel_check < text.index("version-script tailscale"), (
        "wheel check must run before version-script so a refused caller "
        "cannot burn the one-shot version marker"
    )
    assert wheel_check < text.index("tailscale set --operator")
