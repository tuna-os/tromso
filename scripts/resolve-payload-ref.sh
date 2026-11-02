#!/usr/bin/bash
# Resolve tags or indexes to the actual linux/amd64 platform manifest once.
set -euo pipefail
REF=${1:?usage: resolve-payload-ref.sh REGISTRY_REF}
RAW=$(mktemp)
trap 'rm -f "$RAW"' EXIT
skopeo inspect --raw "docker://${REF}" > "$RAW"
if jq -e 'has("manifests")' "$RAW" >/dev/null; then
    DIGEST=$(jq -er '[.manifests[] | select(.platform.os == "linux" and .platform.architecture == "amd64")] | select(length == 1) | .[0].digest' "$RAW")
else
    DIGEST="sha256:$(sha256sum "$RAW" | cut -d ' ' -f1)"
fi
[[ "$DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]
REPOSITORY=${REF%@*}
if [[ "${REPOSITORY##*/}" == *:* ]]; then
    REPOSITORY=${REPOSITORY%:*}
fi
printf '%s@%s\n' "$REPOSITORY" "$DIGEST"
