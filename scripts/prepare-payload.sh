#!/usr/bin/env bash
# Prepare the source-only composefs payload before live-only customization.
# Follows dakota-iso/scripts/payload-oci.sh: root mount config, squash, final diffid.
set -euo pipefail

source_image=${1:?Usage: prepare-payload.sh PINNED_IMAGE NAME}
name=${2:?Missing local image name}
digest=${source_image##*@sha256:}
# Increment the preparation version if the transformation changes, so a cached
# source never silently reuses an earlier payload contract.
prepared="localhost/${name}-payload-v1:${digest}"
if podman image exists "$prepared"; then
    printf '%s\n' "$prepared"
    exit 0
fi

context=$(mktemp -d)
work="localhost/${name}-payload-work:$$"
final_work="localhost/${name}-payload-final-work:$$"
trap 'rm -rf "$context"; podman rmi "$final_work" "$work" >/dev/null 2>&1 || true' EXIT
if ! podman image exists "$source_image"; then
    podman pull "$source_image" >&2
fi
printf 'FROM %s\nCOPY bootc-root-mount.toml /usr/lib/bootc/install/00-defaults.toml\n' \
    "$source_image" > "$context/Containerfile"
printf '[install]\nroot-mount-spec = "LABEL=root"\n' > "$context/bootc-root-mount.toml"
podman build --pull=never --format=oci --squash-all \
    -t "$work" "$context" >&2
diffid=$(podman image inspect "$work" | jq -er \
    '.[0].RootFS.Layers | select(length == 1) | .[0]')
printf 'FROM %s\n' "$work" > "$context/Containerfile"
podman build --pull=never --format=oci --squash-all \
    --label "ostree.final-diffid=$diffid" \
    --annotation "ostree.final-diffid=$diffid" \
    -t "$final_work" "$context" >&2
# Metadata must describe the actual final layer, not a pre-squash layer.
podman image inspect "$final_work" | jq -e --arg diffid "$diffid" \
    '.[0] | .RootFS.Layers == [$diffid] and
     .Labels["ostree.final-diffid"] == $diffid and
     .Annotations["ostree.final-diffid"] == $diffid' >&2
podman tag "$final_work" "$prepared"
printf '%s\n' "$prepared"
