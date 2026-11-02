#!/usr/bin/bash
# Resolve and verify the publisher's immutable image before any channel moves.
set -euo pipefail
SHA=${1:?usage: verify-published-image.sh FULL_COMMIT_SHA}
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo 'Expected a full commit SHA' >&2; exit 1; }
git cat-file -e "${SHA}^{commit}"
IMAGE=ghcr.io/tuna-os/tromso
REF=$(skopeo inspect "docker://${IMAGE}:${SHA}" | jq -er \
    --arg sha "$SHA" --arg image "$IMAGE" \
    'select(.Name == $image and .Labels["org.opencontainers.image.revision"] == $sha) | .Name + "@" + .Digest')
[[ "$REF" =~ ^ghcr\.io/tuna-os/tromso@sha256:[0-9a-f]{64}$ ]]
cosign verify \
    --certificate-identity-regexp '^https://github.com/tuna-os/tromso/\.github/workflows/build-tromso-multirunner\.yml@.*$' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    --certificate-github-workflow-sha "$SHA" "$REF" >&2
printf '%s\n' "$REF"
