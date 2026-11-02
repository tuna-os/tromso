#!/usr/bin/bash
# scripts/lib-install-qemu.sh
# Shared orchestration for the plain and LUKS fisherman-install E2E scripts.
# Sourced by scripts/plain-install-qemu.sh and scripts/luks-install-qemu.sh —
# not meant to be run directly.
#
# Callers must set TARGET, SSH_PORT and MONITOR_LIVE before sourcing,
# then call the functions below in order:
#   install_qemu_init            # sets DISK/PAYLOAD_IMAGE/SSH/SCP/
#                                 # BOOTLOADER/FILESYSTEM and mounts scratch
#   install_qemu_run_fisherman <recipe_tmp_path> <remote_recipe_name> <recipe_json>
#   install_qemu_shutdown

set -euo pipefail

install_qemu_init() {
	DISK="/dev/vda"
	PAYLOAD_IMAGE=$(cat "${TARGET}/payload_ref" | tr -d '[:space:]')
	local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 -o PreferredAuthentications=password -o ServerAliveInterval=30 -o ServerAliveCountMax=20"
	SSH="sshpass -p live ssh $ssh_opts liveuser@127.0.0.1 -p ${SSH_PORT}"
	SCP="sshpass -p live scp $ssh_opts -P ${SSH_PORT}"

	# The ISO's media-input binds the immutable OCI source before disk writes.
	# Missing media is a build error, never a reason to pull a mutable tag.
	$SSH 'sudo test -s /etc/bootc-installer/media-input.json'
	BOOTLOADER=$(cat "${TARGET}/bootloader" 2>/dev/null | tr -d '[:space:]' || echo "systemd")

	# Normalise "grub" → "grub2" for fisherman's recipe validator.
	if [[ "${BOOTLOADER}" == "grub" ]]; then BOOTLOADER="grub2"; fi

	FILESYSTEM="btrfs"

	echo "Mounting scratch disk (/dev/vdb) over /var/tmp..."
	$SSH 'sudo bash -c "
        mkfs.ext4 -F /dev/vdb >/dev/null
        umount /var/tmp 2>/dev/null || true
        mount /dev/vdb /var/tmp
        echo \"/var/tmp is now disk-backed on /dev/vdb\"
    "'
}

# Upload the recipe and run the exact installer shipped on the ISO.
# Every nonzero installer exit fails the test; do not repair the deployment.
install_qemu_run_fisherman() {
	local recipe_tmp="$1"
	local remote_recipe_name="$2"
	local recipe_json="$3"
	printf '%s\n' "${recipe_json}" >"${recipe_tmp}"
	$SCP "${recipe_tmp}" "liveuser@127.0.0.1:/tmp/${remote_recipe_name}"
	echo "Uploaded recipe — running shipped fisherman (takes several minutes)..."
	$SSH "sudo /usr/local/bin/fisherman /tmp/${remote_recipe_name}"
}

install_qemu_shutdown() {
	echo "Install complete. Shutting down live QEMU..."
	local socat_prefix=""
	if ! test -w "${MONITOR_LIVE}" 2>/dev/null; then socat_prefix="sudo"; fi
	echo "system_powerdown" | $socat_prefix socat - "UNIX-CONNECT:${MONITOR_LIVE}" 2>/dev/null || true
	sleep 5
	echo "quit" | $socat_prefix socat - "UNIX-CONNECT:${MONITOR_LIVE}" 2>/dev/null || true
}
