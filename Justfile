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
        --dns=8.8.8.8 \
        --dns=1.1.1.1 \
        -v "{{justfile_directory()}}:/src:rw" \
        -v "${HOME}/.cache/buildstream:/root/.cache/buildstream:rw" \
        -w /src \
        "{{bst2_image}}" \
        bash -c 'bst --colors "$@"' -- ${BST_FLAGS:-} {{ARGS}}

# ── Build log ─────────────────────────────────────────────────────────
# Run build in background, log to /var/tmp/aurora-build.log, tail it
[group('build')]
bst-build *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    LOG=/var/tmp/aurora-build.log
    
    # Clear old log to keep only the most recent run
    if [ -f "$LOG" ]; then
        echo "==> Clearing old build log"
        : > "$LOG"
    fi
    
    echo "=== Build started at $(date) ===" > "$LOG"
    BST_FLAGS="--max-jobs $(($(nproc) / 2)) --fetchers $(nproc) ${BST_FLAGS:-}"
    just bst build ${ARGS:-oci/aurora.bst} >> "$LOG" 2>&1 &
    echo "BST PID: $! — tailing $LOG (Ctrl-C stops tail, build continues)"
    tail -f "$LOG"

[group('build')]
log:
    tail -f /var/tmp/aurora-build.log

# Launch live HTML build dashboard at http://localhost:8765
# Downloads bst-dashboard.py from GitHub on first run; cached at ~/.cache/bst-dashboard/
[group('build')]
dashboard:
    #!/usr/bin/env bash
    set -euo pipefail
    SCRIPT="${HOME}/.cache/bst-dashboard/bst-dashboard.py"
    if [ ! -f "$SCRIPT" ]; then
        echo "Downloading bst-dashboard (run 'just dashboard-update' to upgrade)…"
        mkdir -p "$(dirname "$SCRIPT")"
        curl -fsSL https://raw.githubusercontent.com/hanthor/buildstream-dashboard/main/bst-dashboard.py \
            -o "$SCRIPT"
    fi
    python3 "$SCRIPT" \
        --log /var/tmp/aurora-build.log \
        --target oci/aurora.bst \
        --project "{{justfile_directory()}}" &>/tmp/bst-dashboard.log &
    disown
    echo "Dashboard starting (log: /tmp/bst-dashboard.log)"
    for i in $(seq 1 20); do
        sleep 0.3
        if curl -sf http://localhost:8765/ > /dev/null 2>&1; then
            echo "Dashboard ready at http://localhost:8765/"
            xdg-open http://localhost:8765/ 2>/dev/null || true
            break
        fi
    done

# Pull the latest bst-dashboard from GitHub
[group('build')]
dashboard-update:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/bst-dashboard"
    echo "Updating bst-dashboard…"
    curl -fsSL https://raw.githubusercontent.com/hanthor/buildstream-dashboard/main/bst-dashboard.py \
        -o "${HOME}/.cache/bst-dashboard/bst-dashboard.py"
    echo "Done."

# Install bst-dashboard as a systemd user service
[group('build')]
dashboard-service:
    #!/usr/bin/env bash
    set -euo pipefail
    JUSTDIR="{{justfile_directory()}}"
    IMAGE_NAME="{{image_name}}"
    SERVICE_FILE="${HOME}/.config/systemd/user/bst-dashboard.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
    printf '%s\n' \
      '[Unit]' \
      'Description=BuildStream Build Dashboard' \
      'After=network.target' \
      '' \
      '[Service]' \
      'Type=simple' \
      'Environment=PYTHONUNBUFFERED=1' \
      "ExecStart=/usr/bin/python3 ${JUSTDIR}/bst-dashboard.py --log /var/tmp/${IMAGE_NAME}-build.log --target oci/${IMAGE_NAME}.bst --project ${JUSTDIR}" \
      'Restart=always' \
      'RestartSec=5' \
      '' \
      '[Install]' \
      'WantedBy=default.target' > "$SERVICE_FILE"
    systemctl --user daemon-reload
    systemctl --user enable bst-dashboard.service
    systemctl --user restart bst-dashboard.service
    sudo loginctl enable-linger $USER
    echo "Dashboard service started and enabled (linger enabled)."

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
    if [ -n "${OCI_IMAGE_VERSION}" ]; then
        LABEL_ARGS="${LABEL_ARGS} --label org.opencontainers.image.version=${OCI_IMAGE_VERSION}"
    fi
    DATE_TAG="$(date -u +%Y%m%d)"
    printf 'FROM %s\nRUN sed -i "s/^VERSION_ID=.*/VERSION_ID=\\"%s\\"/" /usr/lib/os-release \\\n    && sed -i "s/^IMAGE_VERSION=.*/IMAGE_VERSION=\\"%s\\"/" /usr/lib/os-release\n' "$IMAGE_ID" "$DATE_TAG" "$DATE_TAG" \
        | $SUDO_CMD podman build --pull=never --security-opt label=type:unconfined_t --squash-all ${LABEL_ARGS} -t "{{image_name}}:{{image_tag}}" -f - .
    $SUDO_CMD podman rmi "$IMAGE_ID" || true
    echo "==> Export complete: {{image_name}}:{{image_tag}}"
    just chunkify "{{image_name}}:{{image_tag}}"

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
        echo "ERROR: Image '{{image_name}}:{{image_tag}}' not found in podman." >&2
        echo "Run 'just build' first to build and export the OCI image." >&2
        exit 1
    fi

    if [ ! -e "${base_dir}/bootable.raw" ] ; then
        echo "==> Creating 30G sparse disk image..."
        fallocate -l 30G "${base_dir}/bootable.raw"
    fi

    echo "==> Installing OS to disk image via bootc..."
    just bootc install to-disk \
        --via-loopback /data/bootable.raw \
        --filesystem "${filesystem}" \
        --wipe \
        --composefs-backend \
        --bootloader systemd \
        --karg systemd.firstboot=no \
        --karg splash \
        --karg quiet \
        --karg console=tty0 \
        --karg console=ttyS0 \
        --karg systemd.debug_shell=ttyS1

    echo "==> Bootable disk image ready: ${base_dir}/bootable.raw"
    sync
    
    # Remove stale qcow2 so boot-vm uses the fresh raw image
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
    for candidate in /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/qemu/OVMF_CODE.fd; do
        if [ -f "$candidate" ]; then OVMF_CODE="$candidate"; break; fi
    done
    if [ -z "$OVMF_CODE" ]; then
        echo "ERROR: OVMF firmware not found. Install edk2-ovmf (Fedora) or ovmf (Debian/Ubuntu)." >&2
        exit 1
    fi

    OVMF_VARS="{{base_dir}}/.ovmf-vars.fd"
    if [ ! -e "$OVMF_VARS" ]; then
        for candidate in /usr/share/edk2/ovmf/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/edk2/x64/OVMF_VARS.4m.fd /usr/share/qemu/OVMF_VARS.fd; do
            if [ -f "$candidate" ]; then cp "$candidate" "$OVMF_VARS"; break; fi
        done
    fi
    echo "==> Booting Aurora via QEMU with VNC (127.0.0.1:5900)..."
    echo "    SSH: ssh -p 2222 root@127.0.0.1 (if ready)"
    qemu-system-x86_64 \
        -enable-kvm -m "{{vm_ram}}" -cpu host -smp "{{vm_cpus}}" \
        -drive file="${DISK}",format=raw,if=virtio \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -device virtio-vga -display vnc=127.0.0.1:0 \
        -device virtio-keyboard -device virtio-mouse \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -serial mon:stdio

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
    if [ ! -x "$FAKECAP_RESTORE" ]; then
        echo "==> Compiling fakecap-restore..."
        gcc -O2 -o "$FAKECAP_RESTORE" "{{justfile_directory()}}/files/fakecap/fakecap-restore.c"
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
    $SUDO_CMD "$FAKECAP_RESTORE" files/fakecap-manifest.tsv "$MERGED"

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
