#!/usr/bin/bash
# scripts/lib-install-qemu.sh
# Shared orchestration for the plain and LUKS fisherman-install E2E scripts.
# Sourced by scripts/plain-install-qemu.sh and scripts/luks-install-qemu.sh —
# not meant to be run directly.
#
# Callers must set TARGET, SSH_PORT, MONITOR_LIVE, FISHER_REPO before sourcing,
# then call the functions below in order:
#   install_qemu_init            # sets DISK/PAYLOAD_IMAGE/SSH/SCP/INSTALL_IMAGE/
#                                 # COMPOSEFS_BACKEND/BOOTLOADER/FILESYSTEM,
#                                 # mounts the scratch disk
#   install_qemu_run_fisherman <recipe_tmp_path> <remote_recipe_name> <composefs_json> <bootcdirect_json>
#   install_qemu_shutdown

set -euo pipefail

install_qemu_init() {
	DISK="/dev/vda"
	local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 -o PreferredAuthentications=password -o ServerAliveInterval=30 -o ServerAliveCountMax=20"
	SSH="sshpass -p live ssh $ssh_opts liveuser@127.0.0.1 -p ${SSH_PORT}"
	SCP="sshpass -p live scp $ssh_opts -P ${SSH_PORT}"

	# Install from the embedded OCI layout that the live media binds in
	# media-input.json, as the graphical installer does. A missing or
	# malformed receipt fails the test; there is no registry fallback.
	local media
	media=$($SSH 'cat /etc/bootc-installer/media-input.json')
	INSTALL_IMAGE=$(jq -er '.image | select(length > 0)' <<<"${media}")
	PAYLOAD_IMAGE=$(jq -er '.targetImgref | select(length > 0)' <<<"${media}")
	echo "Using the embedded media source ${INSTALL_IMAGE} (tracks ${PAYLOAD_IMAGE})."

	# Single-variant repo: optional <target>/composefs and <target>/bootloader
	# files override the defaults (composefs-backed, systemd-boot — dakota style).
	COMPOSEFS_BACKEND=$(cat "${TARGET}/composefs" 2>/dev/null | tr -d '[:space:]' || echo "true")
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

# install_qemu_run_fisherman <recipe_tmp_path> <remote_recipe_name> <composefs_json> <bootcdirect_json>
#
# Writes whichever recipe JSON matches COMPOSEFS_BACKEND to recipe_tmp_path,
# uploads it, and runs fisherman — building a bootcDirect-patched binary from
# FISHER_REPO when composefs is off. Dumps diagnostics and re-raises on failure.
install_qemu_run_fisherman() {
	local recipe_tmp="$1"
	local remote_recipe_name="$2"
	local composefs_json="$3"
	local bootcdirect_json="$4"

	if [[ "${COMPOSEFS_BACKEND}" == "true" ]]; then
		# Composefs path (dakota): install from the embedded media OCI layout.
		printf '%s\n' "${composefs_json}" >"${recipe_tmp}"
		$SCP "${recipe_tmp}" "liveuser@127.0.0.1:/tmp/${remote_recipe_name}"
		echo "Uploaded recipe — running fisherman (takes several minutes)..."
		$SCP "scripts/fisherman-install.sh" liveuser@127.0.0.1:/tmp/fisherman-install.sh
		$SSH "sudo bash /tmp/fisherman-install.sh /tmp/${remote_recipe_name}"
	else
		# Ostree path (stable, lts): bootcDirect — fisherman runs bootc natively.
		# An empty image selects the source bound in media-input.json;
		# targetImgref must equal its day-2 update ref.
		printf '%s\n' "${bootcdirect_json}" >"${recipe_tmp}"
		$SCP "${recipe_tmp}" "liveuser@127.0.0.1:/tmp/${remote_recipe_name}"
		echo "Uploaded recipe — building patched fisherman for bootcDirect..."
		local fisherman_bin
		fisherman_bin=$(mktemp /tmp/fisherman-XXXXXX)
		trap "rm -f '${recipe_tmp}' '${fisherman_bin}'" EXIT
		(cd "${FISHER_REPO}" && CGO_ENABLED=0 go build -o "${fisherman_bin}" ./cmd/fisherman/)
		$SCP "${fisherman_bin}" liveuser@127.0.0.1:/tmp/fisherman
		$SSH 'chmod +x /tmp/fisherman'
		echo "Running fisherman (bootcDirect, takes several minutes)..."
		$SCP "scripts/fisherman-install.sh" liveuser@127.0.0.1:/tmp/fisherman-install.sh
		if ! $SSH "sudo FISHERMAN_BIN=/tmp/fisherman bash /tmp/fisherman-install.sh /tmp/${remote_recipe_name}"; then
			echo "=== INSTALL FAILURE DIAGNOSTICS ==="
			echo "--- dmesg ---"
			$SSH 'sudo dmesg | tail -n 100' || true
			echo "--- journalctl ---"
			$SSH 'sudo journalctl -n 100 --no-pager' || true
			echo "--- systemd-oomd status ---"
			$SSH 'sudo systemctl status systemd-oomd --no-pager' || true
			exit 1
		fi
	fi
}

install_qemu_shutdown() {
	echo "Install complete. Shutting down live QEMU..."
	local socat_prefix=""
	if ! test -w "${MONITOR_LIVE}" 2>/dev/null; then socat_prefix="sudo"; fi
	echo "system_powerdown" | $socat_prefix socat - "UNIX-CONNECT:${MONITOR_LIVE}" 2>/dev/null || true
	sleep 5
	echo "quit" | $socat_prefix socat - "UNIX-CONNECT:${MONITOR_LIVE}" 2>/dev/null || true
}
