#!/usr/bin/env bash
# EXPERIMENT ONLY — export tine's kde-rootfs tar as a bootc-compatible OCI image.
#
# Usage: ./tine-poc/oci-export.sh [image-tag]
# Example: ./tine-poc/oci-export.sh tine-kde:latest
#
# Pipeline: tine buck build -> rootfs tar -> buildah from scratch (+ bootc
# labels) -> bootc container lint. Needs user namespaces (tine builds),
# buildah, and bootc on PATH (bootc only when lint runs).
# Tested on: <not yet run — see docs>.
set -euo pipefail

TAG="tine-kde:latest"
SKIP_LINT=0
for arg in "$@"; do
  case "${arg}" in
    --skip-lint) SKIP_LINT=1 ;;
    -*) echo "ERROR: unknown flag: ${arg}" >&2; exit 1 ;;
    *) TAG="${arg}" ;;
  esac
done

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required tool: $1" >&2
    exit 1
  }
}
need buildah
if [ "${SKIP_LINT}" -ne 1 ]; then
  need bootc
fi

case "$(uname -m)" in
  x86_64) OCI_ARCH="amd64" ;;
  aarch64) OCI_ARCH="arm64" ;;
  *)
    echo "ERROR: unsupported arch: $(uname -m)" >&2
    exit 1
    ;;
esac

echo "==> Building //tine-poc:kde-rootfs with tine..."
tine/bin/tine buck build //tine-poc:kde-rootfs

echo "==> Locating rootfs tar..."
TAR="$(tine/bin/tine buck build --show-output //tine-poc:kde-rootfs | awk '{print $2}' | head -n 1)"
if [ -z "${TAR}" ] || [ ! -f "${TAR}" ]; then
  echo "ERROR: could not locate kde-rootfs tar output (got: '${TAR}')" >&2
  exit 1
fi
echo "    tar: ${TAR}"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
tar -xf "${TAR}" -C "${WORK}"

echo "==> Assembling OCI image ${TAG}..."
CTR="$(buildah from scratch)"
buildah copy "${CTR}" "${WORK}/" /
buildah config \
  --label "containers.bootc=1" \
  --label "ostree.bootable=1" \
  --label "org.opencontainers.image.title=tine-kde (experiment)" \
  --os linux --arch "${OCI_ARCH}" \
  "${CTR}"
buildah commit "${CTR}" "${TAG}"
buildah rm "${CTR}" >/dev/null

if [ "${SKIP_LINT}" -eq 1 ]; then
  echo "==> WARNING: bootc container lint SKIPPED (--skip-lint); ${TAG} is unvalidated"
else
  echo "==> Running bootc container lint..."
  bootc container lint "${TAG}"
  echo "==> OK: ${TAG} passed bootc container lint"
fi
