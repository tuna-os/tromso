#!/usr/bin/bash
# scripts/plain-install-qemu.sh
# Run fisherman with a plain (unencrypted) recipe via SSH into the live QEMU
# VM. Mirrors scripts/luks-install-qemu.sh minus everything LUKS-specific —
# this is the install path most users actually run. Shared orchestration
# lives in scripts/lib-install-qemu.sh.

set -euo pipefail

if [[ $# -lt 4 ]]; then
	echo "Usage: $0 <target> <ssh_port> <monitor_live_socket> <fisher_repo>" >&2
	exit 1
fi

TARGET="$1"
SSH_PORT="$2"
MONITOR_LIVE="$3"
FISHER_REPO="$4"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-install-qemu.sh
source "${SCRIPT_DIR}/lib-install-qemu.sh"

install_qemu_init

RECIPE_TMP=$(mktemp /tmp/plain-recipe-XXXXXX.json)
trap 'rm -f "${RECIPE_TMP}"' EXIT

COMPOSEFS_JSON=$(printf '{\n  "disk": "%s",\n  "filesystem": "%s",\n  "image": "%s",\n  "composeFsBackend": true,\n  "bootloader": "%s",\n  "hostname": "tromso-plain-test",\n  "encryption": {"type": "none"},\n  "flatpaks": []\n}\n' \
	"${DISK}" "${FILESYSTEM}" "${INSTALL_IMAGE}" "${BOOTLOADER}")
BOOTCDIRECT_JSON=$(printf '{\n  "disk": "%s",\n  "filesystem": "%s",\n  "image": "",\n  "targetImgref": "%s",\n  "composeFsBackend": false,\n  "bootloader": "%s",\n  "hostname": "tromso-plain-test",\n  "encryption": {"type": "none"},\n  "flatpaks": []\n}\n' \
	"${DISK}" "${FILESYSTEM}" "${PAYLOAD_IMAGE}" "${BOOTLOADER}")

install_qemu_run_fisherman "${RECIPE_TMP}" "${COMPOSEFS_JSON}" "${BOOTCDIRECT_JSON}"

echo "Patching BLS entries to enable dual serial+VT console..."
$SSH 'sudo bash -c "
    set -euo pipefail
    BOOT_PART=\"/dev/vda1\"
    if ls /dev/vda3 >/dev/null 2>&1; then
        echo \"Detected 3 partitions layout (separate boot partition for GRUB)\"
        BOOT_PART=\"/dev/vda2\"
    fi
    TMP=\$(mktemp -d)
    trap \"umount \$TMP 2>/dev/null || true; rmdir \$TMP\" EXIT
    mount \"\$BOOT_PART\" \$TMP
    COUNT=0
    for entry in \$TMP/loader/entries/*.conf \$TMP/EFI/loader/entries/*.conf; do
        [[ -f \"\$entry\" ]] || continue
        if grep -q \"^options \" \"\$entry\" && ! grep -q \"console=tty0\" \"\$entry\"; then
            sed -i \"s|^options .*|& console=tty0 console=ttyS0|\" \"\$entry\"
            COUNT=\$((COUNT+1))
            echo \"  patched: \$(basename \$entry)\"
        fi
    done
    echo \"BLS patch: \$COUNT entries updated\"
"'

install_qemu_shutdown
