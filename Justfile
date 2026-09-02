# ISO/live/e2e recipes live in iso.justfile (kept separate for readability)
import "iso.justfile"

# List available commands
[group('info')]
default:
    @just --list

# ── Configuration ─────────────────────────────────────────────────────
export image_name := env("BUILD_IMAGE_NAME", "tromso")
export image_tag := env("BUILD_IMAGE_TAG", "latest")
export base_dir := env("BUILD_BASE_DIR", ".")
export filesystem := env("BUILD_FILESYSTEM", "ext4")

# Same bst2 container image CI uses -- pinned by SHA for reproducibility
export bst2_image := env("BST2_IMAGE", "registry.gitlab.com/freedesktop-sdk/infrastructure/freedesktop-sdk-docker-images/bst2:64eb0b4930d57a92710822898fb73af6cc1ae35d")

# VM settings
export vm_ram := env("VM_RAM", "8192")
export vm_cpus := env("VM_CPUS", "4")

# OCI metadata (dynamic labels)
export OCI_IMAGE_CREATED := env("OCI_IMAGE_CREATED", "")
export OCI_IMAGE_REVISION := env("OCI_IMAGE_REVISION", "")
export OCI_IMAGE_VERSION := env("OCI_IMAGE_VERSION", "latest")

import "just/buildstream.just"
import "just/disk-vm.just"

# ── Build ─────────────────────────────────────────────────────────────
[group('build')]
build:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Building Aurora Tromso OCI image with BuildStream..."
    BST_FLAGS="--no-interactive " just bst build oci/tromso.bst
    just export

# ── Export ─────────────────────────────────────────────────────────────
[group('build')]
export:
    #!/usr/bin/env bash
    set -euo pipefail
    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi
    echo "==> Exporting Aurora Tromso OCI image..."
    rm -rf .build-out
    just bst artifact checkout oci/tromso.bst --directory /src/.build-out
    echo "==> Loading and squashing OCI image..."
    IMAGE_ID=$($SUDO_CMD podman pull -q oci:.build-out)
    rm -rf .build-out
    LABEL_ARGS=""
    if [ -n "${OCI_IMAGE_CREATED}" ]; then
        LABEL_ARGS="${LABEL_ARGS} --label org.opencontainers.image.created=${OCI_IMAGE_CREATED}"
    fi
    if [ -n "${OCI_IMAGE_REVISION}" ]; then
        LABEL_ARGS="${LABEL_ARGS} --label org.opencontainers.image.revision=${OCI_IMAGE_REVISION}"
    fi
    if [ -n "${OCI_IMAGE_VERSION}" ]; then
        LABEL_ARGS="${LABEL_ARGS} --label org.opencontainers.image.version=${OCI_IMAGE_VERSION}"
    fi
    DATE_TAG="$(date -u +%Y%m%d)"
    printf 'FROM %s\nRUN sed -i "s/^VERSION_ID=.*/VERSION_ID=\\"%s\\"/" /usr/lib/os-release \\\n    && sed -i "s/^IMAGE_VERSION=.*/IMAGE_VERSION=\\"%s\\"/" /usr/lib/os-release\n' "$IMAGE_ID" "$DATE_TAG" "$DATE_TAG" \
        | $SUDO_CMD podman build --pull=never --security-opt label=type:unconfined_t ${LABEL_ARGS} -t "{{image_name}}:{{image_tag}}" -f - .
    $SUDO_CMD podman rmi "$IMAGE_ID" || true
    echo "==> Export complete: {{image_name}}:{{image_tag}}"
    # Chunkify optimises the image for ostree/composefs distribution but may
    # fail if the overlay diff layer contains whiteout char devices (issue #20).
    # Treat it as non-fatal so GHCR push succeeds even if chunking is skipped.
    just chunkify "{{image_name}}:{{image_tag}}" || \
        echo "==> Warning: chunkify failed (see issue #20); image will be pushed unchunked"

# ── Clean ─────────────────────────────────────────────────────────────
[group('build')]
clean:
    rm -f bootable.raw .ovmf-vars.fd
    rm -rf .build-out

# ── Chunkah ──────────────────────────────────────────────────────────
chunkify image_ref:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Chunkifying {{image_ref}}..."
    CONFIG=$($SUDO_CMD podman inspect "{{image_ref}}")

    FAKECAP_RESTORE="{{justfile_directory()}}/files/fakecap/fakecap-restore"
    FAKECAP_RESTORE_SRC="{{justfile_directory()}}/files/fakecap/fakecap-restore.c"
    FAKECAP_MANIFEST="{{justfile_directory()}}/files/fakecap-manifest.tsv"

    # Tromso doesn't currently version Dakota's generated fakecap manifest.
    # Skip chunkifying when those inputs are absent so `just build` still succeeds.
    if [ ! -f "$FAKECAP_RESTORE_SRC" ] || [ ! -f "$FAKECAP_MANIFEST" ]; then
        echo "==> Skipping chunkify: missing fakecap inputs ($FAKECAP_RESTORE_SRC, $FAKECAP_MANIFEST)."
        exit 0
    fi

    if [ ! -x "$FAKECAP_RESTORE" ]; then
        echo "==> Compiling fakecap-restore..."
        gcc -O2 -o "$FAKECAP_RESTORE" "$FAKECAP_RESTORE_SRC"
    fi

    LOWER=$($SUDO_CMD podman image mount "{{image_ref}}")

    cleanup() {
        $SUDO_CMD umount "$MERGED" 2>/dev/null || true
        $SUDO_CMD rm -rf "$UPPER" "$WORK" "$MERGED"
        $SUDO_CMD podman image umount "{{image_ref}}" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    UPPER=$(mktemp -d -p /var/tmp)
    WORK=$(mktemp -d -p /var/tmp)
    MERGED=$(mktemp -d -p /var/tmp)
    $SUDO_CMD chmod 755 "$UPPER" "$WORK" "$MERGED"
    $SUDO_CMD mount -t overlay overlay \
        -o "lowerdir=${LOWER},upperdir=${UPPER},workdir=${WORK}" \
        "$MERGED"

    echo "==> Applying user.component xattrs via fakecap-restore..."
    $SUDO_CMD "$FAKECAP_RESTORE" "$FAKECAP_MANIFEST" "$MERGED"

    CHUNKAH_REF="quay.io/coreos/chunkah@sha256:306371251e61cc870c8546e225b13bdf2e333f79461dc5e0fc280cc170cee070"
    for attempt in 1 2 3; do
        $SUDO_CMD podman pull "$CHUNKAH_REF" && break
        echo "==> chunkah pull attempt $attempt failed, retrying in 10s..."
        [ "$attempt" -lt 3 ] && sleep 10
    done

    LOADED=$($SUDO_CMD podman run --rm \
        --pull never \
        --security-opt label=type:unconfined_t \
        -v "${MERGED}:/chunkah:ro" \
        -e "CHUNKAH_ROOTFS=/chunkah" \
        -e "CHUNKAH_CONFIG_STR=$CONFIG" \
        "$CHUNKAH_REF" build --max-layers 120 --prune /sysroot/ \
        --label ostree.commit- --label ostree.final-diffid- \
        | $SUDO_CMD podman load)

    echo "$LOADED"

    NEW_REF=$(echo "$LOADED" | sed -n 's/^Loaded image(s): //p; s/^Loaded image: //p' | head -1)
    if [ -z "$NEW_REF" ]; then
        NEW_REF=$(echo "$LOADED" | grep -oP '^[0-9a-f]{64}$' | head -1 || true)
    fi

    if [ -n "$NEW_REF" ] && [ "$NEW_REF" != "{{image_ref}}" ]; then
        echo "==> Retagging chunked image to {{image_ref}}..."
        $SUDO_CMD podman tag "$NEW_REF" "{{image_ref}}"
    fi

# ── Unit tests ───────────────────────────────────────────────────────
[group('test')]
test:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Running BATS unit tests..."
    bats tests/bats/*.bats
    echo "==> Running Pytest suite..."
    pytest tests/pytest/ -v --tb=short

# ── Lint ─────────────────────────────────────────────────────────────
[group('test')]
lint:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Linting {{image_name}}:{{image_tag}} with bootc container lint..."
    $SUDO_CMD podman run --rm --privileged --pull=never \
        "{{image_name}}:{{image_tag}}" \
        bootc container lint
