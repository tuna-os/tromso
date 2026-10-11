#!/usr/bin/bash
# fisherman-install.sh — run fisherman with composefs hostname-write workaround.
#
# fisherman exits non-zero on composefs sysroots when writing hostname because
# it calls `ostree admin --print-current-dir` (against the running system, not the
# target) AFTER unmounting the target disk.  On a composefs/bootc deployment that
# uses ostree/bootc/ instead of ostree/deploy/default/, the command returns exit 1.
# The OS install itself is complete; only this post-unmount hostname step fails.
#
# This wrapper detects that specific failure, re-mounts the installed root
# (unlocking LUKS first when needed), locates /etc in the deployment directory
# tree, and writes the hostname directly.
#
# Exit contract: this script is the e2e install gate. It exits non-zero unless
# the install completed AND every patch it decided was required actually
# landed. A patch that could not be applied is a failed install, not a
# warning: when fisherman exits non-zero because the hostname write failed,
# this wrapper is the only thing that writes the hostname, so a silent patch
# failure makes CI report a pass for a system the installer never finished.
# A patch that is not required on this layout is skipped, which is a pass.
#
# Upstream bug: https://github.com/tuna-os/fisherman/issues
#
# Usage: fisherman-install.sh <recipe.json>
#   recipe.json must contain a "hostname" key (and "encryption.passphrase" for
#   LUKS installs) whose values are used when patching on failure.

set -euo pipefail

RECIPE="${1:-/tmp/plain-recipe.json}"
FISHERMAN_BIN="${FISHERMAN_BIN:-/usr/local/bin/fisherman}"

FISH_RC=0
"$FISHERMAN_BIN" "$RECIPE" >/tmp/fish.log 2>&1 || FISH_RC=$?
cat /tmp/fish.log

PATCH_HOSTNAME=0

if [[ $FISH_RC -ne 0 ]]; then
	# Non-zero exit — check whether only the hostname write failed.
	# Match two patterns:
	# 1. Old fisherman: exits via ostree admin --print-current-dir on composefs sysroots
	# 2. New fisherman: exits with "reading composefs deploy base" when state/deploy not found
	if grep -q "writing hostname" /tmp/fish.log &&
		{ grep -q "ostree admin --print-current-dir" /tmp/fish.log ||
			grep -q "composefs deploy\|state/deploy\|no such file or directory" /tmp/fish.log; }; then
		echo "==> fisherman hostname write failed (composefs/ostree compat bug) — patching manually"
		PATCH_HOSTNAME=1
	else
		echo "==> fisherman failed for a non-hostname reason (rc=$FISH_RC) — propagating"
		exit "$FISH_RC"
	fi
else
	echo "==> fisherman succeeded"
fi

# The hostname patch is the only thing this wrapper applies, so when fisherman
# wrote the hostname itself there is nothing left to do. Mounting the installed
# root anyway would only add a way for a successful install to fail the gate.
if [[ $PATCH_HOSTNAME -eq 0 ]]; then
	echo "==> no post-install patch required"
	exit 0
fi

# Detect whether this is a LUKS install (crypto_LUKS partition on /dev/vda)
# or a plain btrfs install.
# Use -r (raw) to suppress lsblk tree characters (├─/└─) in the NAME field.
# lsblk's own failure is tolerated here and reported as "no partition found"
# below: under set -e an unreadable /dev/vda would otherwise abort the script
# with lsblk's exit code, losing the reason and skipping the teardown.
BLOCKDEVS=$(lsblk -nrpo NAME,FSTYPE /dev/vda 2>&1) || BLOCKDEVS=""
LUKS_DEV=$(awk '$2=="crypto_LUKS"{print $1;exit}' <<<"$BLOCKDEVS")
ROOT_DEV=$(awk '$2=="btrfs"||$2=="xfs"{print $1;exit}' <<<"$BLOCKDEVS")

MNT=$(mktemp -d /tmp/post-install-fix-XXXX)
MAPPER="post-install-fix-$$"
MOUNTED=0

# fail records a reason the installed system is not in the state this script
# was supposed to leave it in. Reasons are collected rather than exited on so
# the log still shows every problem and the mounts are still released below.
FAILURES=()
fail() {
	echo "ERROR: $1"
	FAILURES+=("$1")
}

if [[ -n "$LUKS_DEV" ]]; then
	# LUKS install: extract passphrase from recipe JSON and unlock the container.
	PASSPHRASE=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('encryption', {}).get('passphrase', ''))
" "$RECIPE" 2>/dev/null || echo "")
	if [[ -z "$PASSPHRASE" ]]; then
		fail "could not extract LUKS passphrase from recipe — post-install patch not applied"
	elif printf '%s' "$PASSPHRASE" | cryptsetup luksOpen --key-file=- --batch-mode "$LUKS_DEV" "$MAPPER" 2>/tmp/cryptsetup-err.log; then
		if mount "/dev/mapper/$MAPPER" "$MNT"; then
			MOUNTED=1
		else
			fail "mount /dev/mapper/$MAPPER failed — post-install patch not applied"
			cat /tmp/cryptsetup-err.log 2>/dev/null || true
			cryptsetup luksClose "$MAPPER" || true
		fi
	else
		fail "cryptsetup luksOpen $LUKS_DEV failed — post-install patch not applied"
		cat /tmp/cryptsetup-err.log 2>/dev/null || true
	fi
elif [[ -n "$ROOT_DEV" ]]; then
	# Plain btrfs/xfs install: mount directly. No subvol=@ since we no longer
	# use btrfs subvolumes — the OS is at the btrfs root.
	if mount "$ROOT_DEV" "$MNT"; then
		MOUNTED=1
	else
		fail "mount $ROOT_DEV failed — post-install patch not applied"
	fi
else
	fail "no btrfs, xfs, or crypto_LUKS partition found on /dev/vda — post-install patch not applied"
fi

if [[ $MOUNTED -eq 1 ]]; then
	# Locate /etc in the deployment.
	#   composefs/bootc layout: ostree/bootc/deploy/<stateroot>/<checksum>/etc
	#   classic ostree layout:  ostree/deploy/<stateroot>/deploy/<checksum>/etc
	DEPLOY_ETC=""
	DEPLOY_ETC=$(find "$MNT/ostree/bootc/deploy" -maxdepth 3 -name etc -type d 2>/dev/null | head -1) ||
		true
	if [[ -z "$DEPLOY_ETC" ]]; then
		DEPLOY_ETC=$(find "$MNT/ostree/deploy" -maxdepth 4 -name etc -type d 2>/dev/null | head -1) ||
			true
	fi

	if [[ -n "$DEPLOY_ETC" ]]; then
		# Patch hostname if fisherman failed to write it.
		if [[ $PATCH_HOSTNAME -eq 1 ]]; then
			# Extract hostname from the recipe JSON.
			HOSTNAME=$(grep -o '"hostname"[[:space:]]*:[[:space:]]*"[^"]*"' "$RECIPE" |
				grep -o '"[^"]*"$' | tr -d '"' || echo "tromso")
			if echo "$HOSTNAME" >"$DEPLOY_ETC/hostname"; then
				echo "==> hostname '$HOSTNAME' written to $DEPLOY_ETC/hostname"
			else
				fail "writing hostname to $DEPLOY_ETC/hostname failed — fisherman could not write it either, so the install is incomplete"
			fi
		fi
	else
		fail "deployment etc/ not found under $MNT/ostree — post-install patches not applied"
	fi

	umount -R "$MNT" || true
	if [[ -n "$LUKS_DEV" ]]; then
		cryptsetup luksClose "$MAPPER" || true
	fi
fi

rmdir "$MNT" || true

if ((${#FAILURES[@]} > 0)); then
	echo "==> post-install patch FAILED (${#FAILURES[@]} problem(s)):"
	for reason in "${FAILURES[@]}"; do
		echo "      - $reason"
	done
	exit 1
fi

echo "==> post-install patch complete"
