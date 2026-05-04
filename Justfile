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
    mkdir -p "${HOME}/.cache/buildstream" "${HOME}/.cargo" "${HOME}/.config/buildstream"

    podman --cgroup-manager=cgroupfs run --rm \
        --privileged \
        --device /dev/fuse \
        --network=host \
        -v "{{justfile_directory()}}:/src:rw" \
        -v "${HOME}/.cache/buildstream:/root/.cache/buildstream:rw" \
        -v "${HOME}/.cargo:/root/.cargo:ro" \
        -v "${HOME}/.config/buildstream:/root/.config/buildstream:ro" \
        -w /src \
        "{{bst2_image}}" \
        bash -c 'if [ -t 1 ]; then bst --colors "$@"; else bst --no-colors "$@"; fi' -- ${BST_FLAGS:-} {{ARGS}}

# ── BuildStream via systemd-nspawn (experimental) ──────────────────────
# Run bst2 in systemd-nspawn container instead of podman (less restrictive networking)
# Usage: just bst-nspawn build oci/aurora.bst
[group('dev')]
bst-nspawn *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/buildstream" "${HOME}/.cargo"
    LOG=/tmp/aurora-build.log

    # Extract bst2 OCI image to temporary directory
    echo "==> Extracting bst2 container image..." | tee -a "$LOG"
    CONTAINER_ID=$(podman create "{{bst2_image}}")
    ROOTFS=$(mktemp -d)
    trap "podman rm -f $CONTAINER_ID 2>/dev/null; sudo rm -rf $ROOTFS 2>/dev/null" EXIT

    podman export "$CONTAINER_ID" | tar -x -C "$ROOTFS"
    echo "✓ Image extracted to $ROOTFS" | tee -a "$LOG"

    # Run systemd-nspawn container
    echo "==> Running bst in systemd-nspawn..." | tee -a "$LOG"
    set +e
    sudo systemd-nspawn \
        --directory="$ROOTFS" \
        --bind="{{justfile_directory()}}:/src" \
        --bind="${HOME}/.cache/buildstream:/root/.cache/buildstream" \
        --bind-ro="${HOME}/.cargo:/root/.cargo" \
        --chdir=/src \
        --capability=all \
        /bin/bash -c 'cd /src && bst --colors {{ARGS}}' >> "$LOG" 2>&1
    BST_EXIT=$?
    set -e

    # Also display to console
    tail -50 "$LOG" | grep -A 999999 "Running bst in systemd-nspawn" || true
    exit $BST_EXIT

# ── Build log ─────────────────────────────────────────────────────────
# Run build in background, log to /tmp/aurora-build.log, tail it
[group('build')]
bst-build *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    LOG=/tmp/aurora-build.log

    # Clear old log to keep only the most recent run
    if [ -f "$LOG" ]; then
        echo "==> Clearing old build log"
        : > "$LOG"
    fi

    echo "=== Build started at $(date) ===" > "$LOG"
    FETCHERS="${BST_FETCHERS:-$(nproc)}"
    BST_FLAGS="--max-jobs $(($(nproc) / 2)) --fetchers ${FETCHERS} ${BST_FLAGS:-}"
    # When invoked with stdout/stderr redirected, write directly to LOG and don't tail
    # (tailing the same file we write to creates an exponential feedback loop).
    if [ -t 1 ]; then
        just bst build ${ARGS:-oci/aurora.bst} 2>&1 | tee -a "$LOG"
    else
        echo "Non-interactive: writing directly to $LOG (no tail)" >&2
        just bst build ${ARGS:-oci/aurora.bst} >> "$LOG" 2>&1
    fi

[group('build')]
log:
    tail -f /tmp/aurora-build.log

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
        --log /tmp/aurora-build.log \
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
      "ExecStart=/usr/bin/python3 ${JUSTDIR}/bst-dashboard.py --log /tmp/${IMAGE_NAME}-build.log --target oci/${IMAGE_NAME}.bst --project ${JUSTDIR}" \
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
        | $SUDO_CMD podman build --pull=never --security-opt label=type:unconfined_t ${LABEL_ARGS} -t "{{image_name}}:{{image_tag}}" -f - .
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
    # --bootloader none: our image does not include bootupd (required by --bootloader systemd).
    # We install systemd-boot manually below using files already present in the deployed root.
    just bootc install to-disk \
        --via-loopback /data/bootable.raw \
        --generic-image \
        --filesystem "${filesystem}" \
        --wipe \
        --bootloader none \
        --karg systemd.firstboot=no \
        --karg splash \
        --karg quiet \
        --karg console=tty0 \
        --karg console=ttyS0 \
        --karg systemd.debug_shell=ttyS1

    echo "==> Manually installing systemd-boot EFI files..."
    LOOP=$(sudo losetup -f --show -P "${base_dir}/bootable.raw")
    sudo mkdir -p /mnt/aurora-efi /mnt/aurora-root-efi
    sudo mount "${LOOP}p2" /mnt/aurora-efi
    sudo mount "${LOOP}p3" /mnt/aurora-root-efi
    SYSROOT=$(ls -d /mnt/aurora-root-efi/ostree/deploy/default/deploy/*.0 2>/dev/null | head -1)
    EFI_SRC="${SYSROOT}/usr/lib/systemd/boot/efi"
    sudo install -Dm755 "${EFI_SRC}/systemd-bootx64.efi" /mnt/aurora-efi/EFI/systemd/systemd-bootx64.efi
    sudo install -Dm755 "${EFI_SRC}/systemd-bootx64.efi" /mnt/aurora-efi/EFI/BOOT/BOOTX64.EFI
    ENTRY=$(ls /mnt/aurora-root-efi/boot/loader.1/entries/ostree-1.conf 2>/dev/null | head -1)
    if [ -n "$ENTRY" ]; then
        BOOT_OSTREE=$(grep -Po '(?<=initrd )/boot/ostree/[^ ]+' "$ENTRY" | head -1 | xargs dirname)
        sudo mkdir -p "/mnt/aurora-efi${BOOT_OSTREE}"
        sudo cp -r "/mnt/aurora-root-efi${BOOT_OSTREE}/." "/mnt/aurora-efi${BOOT_OSTREE}/"
        sudo mkdir -p /mnt/aurora-efi/loader/entries
        sudo cp "$ENTRY" /mnt/aurora-efi/loader/entries/
        echo "timeout 5" | sudo tee /mnt/aurora-efi/loader/loader.conf
    fi
    sudo umount /mnt/aurora-efi /mnt/aurora-root-efi
    sudo losetup -d "$LOOP"

    echo "==> Setting root password and SSH authorized_keys..."
    LOOP2=$(sudo losetup -f --show -P "${base_dir}/bootable.raw")
    sudo mkdir -p /mnt/aurora-root-setup
    sudo mount "${LOOP2}p3" /mnt/aurora-root-setup
    DEPLOY2=$(ls -d /mnt/aurora-root-setup/ostree/deploy/default/deploy/*.0 2>/dev/null | head -1)
    # Set root password (hash for 'aurora') in the deploy root
    ROOT_HASH=$(openssl passwd -6 'aurora')
    sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "${DEPLOY2}/etc/shadow"
    # authorized_keys goes in the var overlay (/var/roothome), not deploy root
    # because /root → /var/roothome in ostree at runtime
    VAR_ROOT="/mnt/aurora-root-setup/ostree/deploy/default/var/roothome"
    if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        sudo install -Dm600 -o root -g root "${HOME}/.ssh/id_ed25519.pub" "${VAR_ROOT}/.ssh/authorized_keys"
        sudo chmod 700 "${VAR_ROOT}/.ssh"
        echo "    SSH authorized_keys installed for root"
    fi
    sudo umount /mnt/aurora-root-setup
    sudo losetup -d "$LOOP2"

    echo "==> Bootable disk image ready: ${base_dir}/bootable.raw"
    sync
    
    # Remove stale qcow2 so boot-vm uses the fresh raw image
    rm -f "${base_dir}/bootable.qcow2"

# ── bootc helper ─────────────────────────────────────────────────────
[group('dev')]
bootc *ARGS:
    sudo bash -c 'podman run --rm --privileged --pid=host -v /var/lib/containers:/var/lib/containers -v /run/containers:/run/containers -v /dev:/dev -v "{{base_dir}}:/data" --security-opt label=type:unconfined_t "{{image_name}}:{{image_tag}}" bash -c "/usr/bin/bootc {{ARGS}}"'

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
    echo "==> Booting Aurora in QEMU (background)..."
    echo "    SSH:    ssh -p 2222 -i ~/.ssh/id_ed25519 root@127.0.0.1"
    echo "    Serial: telnet 127.0.0.1 4444"
    echo "    Logs:   tail -f /tmp/aurora-serial.log"
    echo "    Stop:   kill \$(cat /tmp/aurora-vm.pid)"
    QEMU_BIN=""
    for candidate in qemu-system-x86_64 /usr/libexec/qemu-kvm; do
        if command -v "$candidate" &>/dev/null || [ -x "$candidate" ]; then
            QEMU_BIN="$candidate"
            break
        fi
    done
    if [ -z "$QEMU_BIN" ]; then
        echo "ERROR: qemu-system-x86_64 not found. Install qemu-kvm." >&2
        exit 1
    fi
    "$QEMU_BIN" \
        -enable-kvm -m "{{vm_ram}}" -cpu host -smp "{{vm_cpus}}" \
        -drive file="${DISK}",format=raw,if=virtio \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -device virtio-vga -display vnc=127.0.0.1:0 \
        -device virtio-keyboard -device virtio-mouse \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -serial telnet:127.0.0.1:4444,server,nowait \
        -display none \
        -daemonize \
        -pidfile /tmp/aurora-vm.pid

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

    UPPER=$(mktemp -d -p /tmp)
    WORK=$(mktemp -d -p /tmp)
    MERGED=$(mktemp -d -p /tmp)
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

