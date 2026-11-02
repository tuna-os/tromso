#!/usr/bin/bash
# scripts/luks-install-qemu.sh
# Run fisherman LUKS install via SSH into the live QEMU VM.
# Reuses the same SSH logic as plain-install; install disk is /dev/vda in
# QEMU. Shared orchestration lives in scripts/lib-install-qemu.sh.

set -euo pipefail

if [[ $# -lt 4 ]]; then
	echo "Usage: $0 <target> <luks_passphrase> <ssh_port> <monitor_live_socket>" >&2
	exit 1
fi

TARGET="$1"
PASSPHRASE="$2"
SSH_PORT="$3"
MONITOR_LIVE="$4"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-install-qemu.sh
source "${SCRIPT_DIR}/lib-install-qemu.sh"

install_qemu_init

RECIPE_TMP=$(mktemp /tmp/luks-recipe-XXXXXX.json)
trap 'rm -f "${RECIPE_TMP}"' EXIT

COMPOSEFS_JSON=$(printf '{\n  "disk": "%s",\n  "filesystem": "%s",\n  "image": "",\n  "targetImgref": "%s",\n  "composeFsBackend": true,\n  "bootloader": "%s",\n  "hostname": "tromso-luks-test",\n  "encryption": {"type": "luks-passphrase", "passphrase": "%s"},\n  "flatpaks": []\n}\n' \
	"${DISK}" "${FILESYSTEM}" "${PAYLOAD_IMAGE}" "${BOOTLOADER}" "${PASSPHRASE}")

install_qemu_run_fisherman "${RECIPE_TMP}" "luks-recipe.json" "${COMPOSEFS_JSON}"

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
