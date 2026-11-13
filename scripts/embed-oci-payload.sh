#!/usr/bin/bash
# embed-oci-payload.sh — embed the install payload as a read-only OCI layout
# and write the media-input.json receipt that binds fisherman to it.
#
# Fisherman refuses to install from live media (live-iso-mode marker) unless
# /etc/bootc-installer/media-input.json names a verified, read-only OCI
# layout (tuna-os/fisherman internal/install/mediainput.go, schema v1). The
# approach follows tromso#406 and brussels#264.
#
# Usage: embed-oci-payload.sh <payload-oci-archive> <payload-ref> <squashfs-root> <tools-image>
#   payload-oci-archive  squashed payload from `buildah commit --squash`
#   payload-ref          image name in the archive; the receipt's `image`
#   squashfs-root        live root tree that becomes the squashfs
#   tools-image          image that supplies skopeo (the live installer image)

set -euo pipefail

ARCHIVE=${1:?usage: embed-oci-payload.sh ARCHIVE PAYLOAD_REF SQUASHFS_ROOT TOOLS_IMAGE}
IMAGE=${2:?missing payload ref}
ROOT=${3:?missing squashfs root}
TOOLS_IMAGE=${4:?missing tools image}

RELATIVE="usr/lib/tunaos/payload"
LAYOUT="${ROOT}/${RELATIVE}"
# dmsquash-live mounts the squashfs read-only at /run/rootfsbase, below the
# writable live overlay. Fisherman refuses a layout on a writable filesystem.
LIVE_LAYOUT="/run/rootfsbase/${RELATIVE}"
RECIPE="${ROOT}/etc/bootc-installer/recipe.json"
RECEIPT="${ROOT}/etc/bootc-installer/media-input.json"

[[ ! -e "${LAYOUT}" ]] || { echo "ERROR: ${LAYOUT} already exists" >&2; exit 1; }
mkdir -p "${LAYOUT}"

# composefs needs gzip layers (AGENTS.md "OCI Layer Compression"); the
# squashed archive holds one uncompressed layer.
podman run --rm \
	--privileged \
	-v "${ARCHIVE}:/payload.oci.tar:ro" \
	-v "${LAYOUT}:/layout" \
	"${TOOLS_IMAGE}" \
	sh -c "mkdir -p /var/tmp && skopeo copy --dest-compress-format gzip 'oci-archive:/payload.oci.tar:${IMAGE}' oci:/layout:payload"

MANIFEST=$(jq -er '.manifests | select(length == 1) | .[0].digest' "${LAYOUT}/index.json")
[[ "${MANIFEST}" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "ERROR: bad manifest digest ${MANIFEST}" >&2; exit 1; }
CONFIG=$(jq -er '.config.digest' "${LAYOUT}/blobs/sha256/${MANIFEST#sha256:}")
[[ "${CONFIG}" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "ERROR: bad config digest ${CONFIG}" >&2; exit 1; }
PLATFORM=$(jq -er '.os + "/" + .architecture' "${LAYOUT}/blobs/sha256/${CONFIG#sha256:}")
# The installed system tracks the same ref that the graphical installer uses.
TARGET=$(jq -er '.imgref | select(length > 0)' "${RECIPE}")

jq -n \
	--arg image "${IMAGE}" \
	--arg target "${TARGET}" \
	--arg layout "${LIVE_LAYOUT}" \
	--arg manifest "${MANIFEST}" \
	--arg config "${CONFIG}" \
	--arg platform "${PLATFORM}" \
	'{schemaVersion: 1, kind: "tromso-live", image: $image,
	  platformManifestDigest: $manifest, configDigest: $config,
	  ociLayoutPath: $layout, targetImgref: $target, platform: $platform}' \
	>"${RECEIPT}"
cat "${RECEIPT}"
