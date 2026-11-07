#!/usr/bin/env bash
# Publish or restore a complete signed ISO set. R2 credentials come from env.
set -euo pipefail

MODE=${1:?publish, restore or verify}
DATED=${2:?dated ISO basename}
PREFIX=${3:?R2 prefix}
: "${R2_BUCKET:?R2 bucket}"
[[ "$DATED" =~ ^tromso-live-[0-9]{8}-[0-9a-f]{7}\.iso$ ]] || exit 1
[[ "$PREFIX" == tromso || "$PREFIX" == tromso/stable ]] || exit 1
REMOTE="R2:${R2_BUCKET}/${PREFIX}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/dated" "$WORK/latest"

copy() {
    rclone copyto --s3-no-check-bucket "$1" "$2"
}
check() {
    # S3 ETags are not reliable hashes for multipart uploads. Read the bytes.
    rclone check --download --one-way --s3-no-check-bucket "$1" "$REMOTE"
}

case "$MODE" in
    publish)
        ISO=${4:?local ISO path}
        ln "$(realpath "$ISO")" "$WORK/dated/$DATED" || cp --reflink=auto "$ISO" "$WORK/dated/$DATED"
        cp "${ISO}.sig" "$WORK/dated/${DATED}.sig"
        cp "${ISO}.cert" "$WORK/dated/${DATED}.cert"
        (cd "$WORK/dated"; sha256sum "$DATED" > "${DATED}-CHECKSUM")
        for FILE in "$WORK/dated/"*; do
            copy "$FILE" "$REMOTE/$(basename "$FILE")"
        done
        check "$WORK/dated"
        ;;
    restore|verify)
        # Validate the entire historical set before changing any public object.
        for SUFFIX in '' .sig .cert -CHECKSUM; do
            copy "$REMOTE/${DATED}${SUFFIX}" "$WORK/dated/${DATED}${SUFFIX}"
        done
        (cd "$WORK/dated"; sha256sum --check "${DATED}-CHECKSUM")
        cosign verify-blob \
            --signature "$WORK/dated/${DATED}.sig" \
            --certificate "$WORK/dated/${DATED}.cert" \
            --certificate-identity-regexp '^https://github\.com/tuna-os/tromso/\.github/workflows/build-iso\.yml@refs/heads/(main|stable)$' \
            --certificate-oidc-issuer https://token.actions.githubusercontent.com \
            "$WORK/dated/$DATED"
        [[ "$MODE" != verify ]] || exit 0
        ;;
    *) echo "Unknown mode: $MODE" >&2; exit 1 ;;
esac

LATEST=tromso-live-latest.iso
ln "$WORK/dated/$DATED" "$WORK/latest/$LATEST"
cp "$WORK/dated/${DATED}.sig" "$WORK/latest/${LATEST}.sig"
cp "$WORK/dated/${DATED}.cert" "$WORK/latest/${LATEST}.cert"
(cd "$WORK/latest"; sha256sum "$LATEST" > "${LATEST}-CHECKSUM")
# Publish sidecars first and the ISO last; object-store writes are not atomic
# across this set. A failed copy or read-back must fail the workflow.
for SUFFIX in .sig .cert -CHECKSUM ''; do
    if [[ "$SUFFIX" == -CHECKSUM ]]; then
        copy "$WORK/latest/${LATEST}${SUFFIX}" "$REMOTE/${LATEST}${SUFFIX}"
    else
        # Server-side copies avoid re-uploading multi-GB ISO bytes from runners.
        copy "$REMOTE/${DATED}${SUFFIX}" "$REMOTE/${LATEST}${SUFFIX}"
    fi
done
check "$WORK/latest"
URL="https://download.tunaos.org/${PREFIX}/${LATEST}"
curl --fail --silent --show-error --head --max-time 60 "$URL"
echo "$URL"
