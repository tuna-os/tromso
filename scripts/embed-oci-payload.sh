#!/usr/bin/bash
# Bind the immutable registry candidate to the exact bytes transported on media.
set -euo pipefail
SOURCE=${1:?usage: embed-oci-payload.sh SOURCE_TRANSPORT IMMUTABLE_IMAGE ROOT}
IMAGE=${2:?missing immutable image}
ROOT=${3:?missing squashfs root}
[[ "$IMAGE" =~ @sha256:[0-9a-f]{64}$ ]] || { echo 'Payload must name a platform manifest by digest' >&2; exit 1; }
LAYOUT="${ROOT}/usr/lib/tunaos/payload"
# dracut retains this read-only squashfs bind below the writable live overlay.
LIVE_LAYOUT=/run/rootfsbase/usr/lib/tunaos/payload
mkdir -p "$LAYOUT" "${ROOT}/etc/bootc-installer"
skopeo copy --preserve-digests "$SOURCE" "oci:${LAYOUT}:payload"
MANIFEST=$(jq -er '.manifests | select(length == 1) | .[0].digest' "${LAYOUT}/index.json")
[[ "$MANIFEST" == "${IMAGE##*@}" ]] || { echo 'Transported manifest differs from selected candidate' >&2; exit 1; }
CONFIG=$(jq -er '.config.digest' "${LAYOUT}/blobs/sha256/${MANIFEST#sha256:}")
[[ "$CONFIG" =~ ^sha256:[0-9a-f]{64}$ ]]
PLATFORM=$(jq -er '.os + "/" + .architecture' "${LAYOUT}/blobs/sha256/${CONFIG#sha256:}")
[[ "$PLATFORM" == linux/amd64 ]] || { echo "Unsupported payload platform: $PLATFORM" >&2; exit 1; }
RECIPE="${ROOT}/etc/bootc-installer/recipe.json"
UPDATE_REF=$(jq -er '.imgref | select(length > 0)' "$RECIPE")
jq -n --arg image "$IMAGE" --arg target "$UPDATE_REF" --arg layout "$LIVE_LAYOUT" \
    --arg manifest "$MANIFEST" --arg config "$CONFIG" --arg platform "$PLATFORM" \
    '{schemaVersion: 1, kind: "tromso-live", image: $image,
      targetImgref: $target, ociLayoutPath: $layout,
      platformManifestDigest: $manifest, configDigest: $config, platform: $platform}' \
    > "${ROOT}/etc/bootc-installer/media-input.json"
# Both graphical and unattended recipes must request the bound image, not a
# mutable tag or a containers-storage transport spelling of that image.
jq --arg image "$IMAGE" '.imgref = $image | del(.local_imgref)' "$RECIPE" > "${RECIPE}.tmp"
mv "${RECIPE}.tmp" "$RECIPE"
for CATALOG in "${ROOT}/etc/bootc-installer/images.json" "${ROOT}/etc/tuna-installer/images.json"; do
    jq --arg image "$IMAGE" '.default_image = $image | .images[].imgref = $image' "$CATALOG" > "${CATALOG}.tmp"
    mv "${CATALOG}.tmp" "$CATALOG"
done
