#!/usr/bin/bash
# pin-candidate-payload.sh — bind the ISO payload to one release candidate.
#
# promote-stable.yml passes the commit and the OCI digest that one successful
# main build pushed. The checkout must be that commit. The payload is named by
# digest, so a tag that moves during the run cannot change the payload.
#
# Usage: pin-candidate-payload.sh <candidate-sha> <candidate-digest> <payload-ref-file>

set -euo pipefail

SHA=${1:-}
DIGEST=${2:-}
PAYLOAD_REF_FILE=${3:?usage: pin-candidate-payload.sh SHA DIGEST PAYLOAD_REF_FILE}
REPOSITORY=ghcr.io/tuna-os/tromso

[[ "${SHA}" =~ ^[0-9a-f]{40}$ ]] || { echo "ERROR: candidate SHA is not a full commit SHA: '${SHA}'" >&2; exit 1; }
[[ "${DIGEST}" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "ERROR: candidate digest is not sha256:<64 hex>: '${DIGEST}'" >&2; exit 1; }
HEAD=$(git rev-parse HEAD)
[[ "${HEAD}" == "${SHA}" ]] || { echo "ERROR: checkout ${HEAD} is not candidate ${SHA}" >&2; exit 1; }

echo "${REPOSITORY}@${DIGEST}" >"${PAYLOAD_REF_FILE}"
echo "Payload pinned to ${REPOSITORY}@${DIGEST} for ${SHA}"
