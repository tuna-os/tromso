#!/usr/bin/bash
# Build fisherman's immutable offline-media contract from the actual OCI layout.
set -euo pipefail

SOURCE=${1:?usage: embed-oci-payload.sh SOURCE_TRANSPORT UPDATE_REF ROOT}
UPDATE_REF=${2:?missing update ref}
ROOT=${3:?missing squashfs root}
LAYOUT_PATH=/usr/lib/tunaos/payload
LAYOUT="${ROOT}${LAYOUT_PATH}"

mkdir -p "$LAYOUT" "${ROOT}/etc/bootc-installer" "${ROOT}/etc/tuna-installer"
skopeo copy --dest-compress-format gzip --dest-force-compress-format \
    "$SOURCE" "oci:${LAYOUT}:payload"
MANIFEST=$(jq -er '.manifests | select(length == 1) | .[0].digest' "${LAYOUT}/index.json")
[[ "$MANIFEST" =~ ^sha256:[0-9a-f]{64}$ ]]
CONFIG=$(jq -er '.config.digest' "${LAYOUT}/blobs/sha256/${MANIFEST#sha256:}")
[[ "$CONFIG" =~ ^sha256:[0-9a-f]{64}$ ]]
PLATFORM=$(jq -er '.os + "/" + .architecture' "${LAYOUT}/blobs/sha256/${CONFIG#sha256:}")
jq -n --arg image "$UPDATE_REF" --arg layout "$LAYOUT_PATH" \
    --arg manifest "$MANIFEST" --arg config "$CONFIG" --arg platform "$PLATFORM" \
    '{schemaVersion: 1, kind: "tromso-live", image: $image,
      targetImgref: $image, ociLayoutPath: $layout,
      platformManifestDigest: $manifest, configDigest: $config, platform: $platform}' \
    > "${ROOT}/etc/bootc-installer/media-input.json"
# Both unattended recipes and the graphical installer consume the same media.
jq --arg image "$UPDATE_REF" '.imgref = $image' \
    "${ROOT}/etc/bootc-installer/recipe.json" > "${ROOT}/etc/bootc-installer/recipe.json.tmp"
mv "${ROOT}/etc/bootc-installer/recipe.json.tmp" "${ROOT}/etc/bootc-installer/recipe.json"
jq --arg image "$UPDATE_REF" '.default_image = $image | .images[0].imgref = $image' \
    "${ROOT}/etc/bootc-installer/images.json" > "${ROOT}/etc/bootc-installer/images.json.tmp"
mv "${ROOT}/etc/bootc-installer/images.json.tmp" "${ROOT}/etc/bootc-installer/images.json"
cp "${ROOT}/etc/bootc-installer/images.json" "${ROOT}/etc/tuna-installer/images.json"
