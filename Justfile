# List available commands
[group('info')]
default:
    @just --list

# ── Configuration ─────────────────────────────────────────────────────
export image_name := env("BUILD_IMAGE_NAME", "aurora")
export image_tag := env("BUILD_IMAGE_TAG", "latest")
export base_dir := env("BUILD_BASE_DIR", ".")
export filesystem := env("BUILD_FILESYSTEM", "btrfs")

# Same bst2 container image CI uses -- pinned by SHA for reproducibility
export bst2_image := env("BST2_IMAGE", "registry.gitlab.com/freedesktop-sdk/infrastructure/freedesktop-sdk-docker-images/bst2:f89b4aef847ef040b345acceda15a850219eb8f1")

# VM settings
export vm_ram := env("VM_RAM", "8192")
export vm_cpus := env("VM_CPUS", "4")

# OCI metadata (dynamic labels)
export OCI_IMAGE_CREATED := env("OCI_IMAGE_CREATED", "")
export OCI_IMAGE_REVISION := env("OCI_IMAGE_REVISION", "")
export OCI_IMAGE_VERSION := env("OCI_IMAGE_VERSION", "latest")

# ── BuildStream wrapper ──────────────────────────────────────────────
# Runs any bst command inside the bst2 container via podman.
# Usage: just bst build oci/aurora.bst
#        just bst show oci/aurora.bst
[group('dev')]
bst *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/buildstream"
    podman run --rm \
        --privileged \
        --device /dev/fuse \
        --network=host \
        -v "{{justfile_directory()}}:/src:rw" \
        -v "${HOME}/.cache/buildstream:/root/.cache/buildstream:rw" \
        -w /src \
        "{{bst2_image}}" \
        bash -c 'bst --colors "$@"' -- ${BST_FLAGS:-} {{ARGS}}

# ── Build ─────────────────────────────────────────────────────────────
[group('build')]
build:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Building Aurora OCI image with BuildStream..."
    just bst build oci/aurora.bst
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
    echo "==> Exporting Aurora OCI image..."
    rm -rf .build-out
    just bst artifact checkout oci/aurora.bst --directory /src/.build-out
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
    DATE_TAG="$(date -u +%Y%m%d)"
    printf 'FROM %s\nRUN sed -i "s/^VERSION_ID=.*/VERSION_ID=\\"%s\\"/" /usr/lib/os-release\n' "$IMAGE_ID" "$DATE_TAG" \
        | $SUDO_CMD podman build --pull=never --security-opt label=type:unconfined_t --squash-all ${LABEL_ARGS} -t "{{image_name}}:{{image_tag}}" -f - .
    $SUDO_CMD podman rmi "$IMAGE_ID" || true
    echo "==> Export complete: {{image_name}}:{{image_tag}}"

# ── Clean ─────────────────────────────────────────────────────────────
[group('build')]
clean:
    rm -f bootable.raw .ovmf-vars.fd
    rm -rf .build-out

# ── Generate bootable disk image ─────────────────────────────────────
[group('test')]
generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! sudo podman image exists "{{image_name}}:{{image_tag}}"; then
        echo "ERROR: Image '{{image_name}}:{{image_tag}}' not found. Run 'just build' first." >&2
        exit 1
    fi
    if [ ! -e "${base_dir}/bootable.raw" ]; then
        fallocate -l 30G "${base_dir}/bootable.raw"
    fi
    just bootc install to-disk \
        --via-loopback /data/bootable.raw \
        --filesystem "${filesystem}" \
        --wipe \
        --composefs-backend \
        --bootloader systemd \
        --karg systemd.firstboot=no \
        --karg splash \
        --karg quiet \
        --karg console=tty0
    sync
    rm -f "${base_dir}/bootable.qcow2"

# ── bootc helper ─────────────────────────────────────────────────────
[group('dev')]
bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bootc {{ARGS}}

# ── Boot VM ──────────────────────────────────────────────────────────
[group('test')]
boot-vm $base_dir=base_dir:
    #!/usr/bin/env bash
    set -euo pipefail
    DISK=$(realpath "{{base_dir}}/bootable.raw")
    if [ ! -e "$DISK" ]; then
        echo "ERROR: ${DISK} not found. Run 'just generate-bootable-image' first." >&2
        exit 1
    fi
    OVMF_CODE=""
    for candidate in /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd; do
        if [ -f "$candidate" ]; then OVMF_CODE="$candidate"; break; fi
    done
    if [ -z "$OVMF_CODE" ]; then
        echo "ERROR: OVMF firmware not found. Install edk2-ovmf." >&2; exit 1
    fi
    OVMF_VARS="{{base_dir}}/.ovmf-vars.fd"
    if [ ! -e "$OVMF_VARS" ]; then
        for candidate in /usr/share/edk2/ovmf/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS.fd; do
            if [ -f "$candidate" ]; then cp "$candidate" "$OVMF_VARS"; break; fi
        done
    fi
    qemu-system-x86_64 \
        -enable-kvm -m "{{vm_ram}}" -cpu host -smp "{{vm_cpus}}" \
        -drive file="${DISK}",format=raw,if=virtio \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -device virtio-vga -display gtk \
        -device virtio-keyboard -device virtio-mouse \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22
