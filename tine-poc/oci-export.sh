#!/usr/bin/env bash
# EXPERIMENT ONLY — export tine's kde-rootfs tar as a bootc-compatible OCI image.
#
# Usage: ./tine-poc/oci-export.sh [image-tag] [--rule //tine-poc:target] [--skip-lint]
# Example: ./tine-poc/oci-export.sh tine-kde:latest
# Example: ./tine-poc/oci-export.sh tine-utah:race --rule //tine-poc:utah-race-rootfs --skip-lint
#
# Pipeline: tine buck build -> rootfs tar -> buildah from scratch (+ bootc
# labels) -> bootc container lint. Needs user namespaces (tine builds),
# buildah, and bootc on PATH (bootc only when lint runs).
# Tested on: <not yet run — see docs>.
set -euo pipefail

TAG="tine-kde:latest"
RULE="//tine-poc:kde-rootfs"
SKIP_LINT=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-lint) SKIP_LINT=1; shift ;;
    --rule) RULE="$2"; shift 2 ;;
    -*) echo "ERROR: unknown flag: $1" >&2; exit 1 ;;
    *) TAG="$1"; shift ;;
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

echo "==> Building ${RULE} with tine..."
tine/bin/tine buck build "${RULE}"

echo "==> Locating rootfs tar..."
TAR="$(tine/bin/tine buck build --show-output "${RULE}" | awk '{print $2}' | head -n 1)"
if [ -z "${TAR}" ] || [ ! -f "${TAR}" ]; then
  echo "ERROR: could not locate rootfs tar output for ${RULE} (got: '${TAR}')" >&2
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
  --label "org.opencontainers.image.title=${TAG} (tine experiment)" \
  --os linux --arch "${OCI_ARCH}" \
  "${CTR}"
buildah commit "${CTR}" "${TAG}"
buildah rm "${CTR}" >/dev/null

if [ "${SKIP_LINT}" -eq 1 ]; then
  echo "==> WARNING: bootc container lint SKIPPED (--skip-lint); ${TAG} is unvalidated"
else
  # lint takes a rootfs dir, not an image ref (it is designed for
  # `RUN bootc container lint` inside a Containerfile build).
  echo "==> Running bootc container lint..."
  bootc container lint --rootfs "${WORK}"
  echo "==> OK: ${TAG} passed bootc container lint"
fi
