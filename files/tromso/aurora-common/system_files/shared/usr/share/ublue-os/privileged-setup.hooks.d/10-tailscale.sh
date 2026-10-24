#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

# Only an administrator (member of wheel) may become the Tailscale operator.
# PKEXEC_UID is whoever invoked the helper, so do not trust it blindly. This
# runs before version-script so a refused caller does not consume the one-shot
# version marker meant for the machine's administrator.
OPERATOR_USER=""
if [[ "${PKEXEC_UID:-}" =~ ^[0-9]+$ ]] && [ "${PKEXEC_UID}" -ne 0 ] ; then
	OPERATOR_USER="$(getent passwd "$PKEXEC_UID" | cut -d: -f1)"
fi

if [ -z "${OPERATOR_USER}" ] || ! id -nG "${OPERATOR_USER}" | tr ' ' '\n' | grep -qx wheel ; then
	echo "Skipping tailscale operator setup: invoking user is not a wheel member"
	exit 0
fi

version-script tailscale privileged 1 || exit 0

set -xeuo pipefail

tailscale set --operator="${OPERATOR_USER}"
