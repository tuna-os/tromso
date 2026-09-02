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
        --karg console=tty0 \
        --karg console=ttyS0 \
        --karg systemd.debug_shell=ttyS1

    echo "==> Manually installing systemd-boot EFI files..."
    LOOP=$(sudo losetup -f --show -P "${base_dir}/bootable.raw")
    sudo mkdir -p /mnt/tromso-efi /mnt/tromso-root-efi
    sudo mount "${LOOP}p2" /mnt/tromso-efi
    sudo mount "${LOOP}p3" /mnt/tromso-root-efi
    SYSROOT=$(ls -d /mnt/tromso-root-efi/ostree/deploy/default/deploy/*.0 2>/dev/null | head -1)
    EFI_SRC="${SYSROOT}/usr/lib/systemd/boot/efi"
    sudo install -Dm755 "${EFI_SRC}/systemd-bootx64.efi" /mnt/tromso-efi/EFI/systemd/systemd-bootx64.efi
    sudo install -Dm755 "${EFI_SRC}/systemd-bootx64.efi" /mnt/tromso-efi/EFI/BOOT/BOOTX64.EFI
    ENTRY=$(ls /mnt/tromso-root-efi/boot/loader.1/entries/ostree-1.conf 2>/dev/null | head -1)
    if [ -n "$ENTRY" ]; then
        BOOT_OSTREE=$(grep -Po '(?<=initrd )/boot/ostree/[^ ]+' "$ENTRY" | head -1 | xargs dirname)
        sudo mkdir -p "/mnt/tromso-efi${BOOT_OSTREE}"
        sudo cp -r "/mnt/tromso-root-efi${BOOT_OSTREE}/." "/mnt/tromso-efi${BOOT_OSTREE}/"
        sudo mkdir -p /mnt/tromso-efi/loader/entries
        sudo cp "$ENTRY" /mnt/tromso-efi/loader/entries/
        echo "timeout 5" | sudo tee /mnt/tromso-efi/loader/loader.conf
    fi
    sudo umount /mnt/tromso-efi /mnt/tromso-root-efi
    sudo losetup -d "$LOOP"

    echo "==> Setting root password and SSH authorized_keys..."
    LOOP2=$(sudo losetup -f --show -P "${base_dir}/bootable.raw")
    sudo mkdir -p /mnt/tromso-root-setup
    sudo mount "${LOOP2}p3" /mnt/tromso-root-setup
    DEPLOY2=$(ls -d /mnt/tromso-root-setup/ostree/deploy/default/deploy/*.0 2>/dev/null | head -1)
    # Set root password (hash for 'aurora') in the deploy root
    ROOT_HASH=$(openssl passwd -6 'aurora')
    sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "${DEPLOY2}/etc/shadow"
    # authorized_keys: write to the ostree live var (ostree/deploy/default/var/),
    # which is what /var maps to at runtime via bind mount — NOT the deploy
    # checkout's var/ (which is read-only and not mounted as /var).
    VAR_ROOT="/mnt/tromso-root-setup/ostree/deploy/default/var/roothome"
    if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        sudo install -Dm600 -o root -g root "${HOME}/.ssh/id_ed25519.pub" "${VAR_ROOT}/.ssh/authorized_keys"
        sudo chmod 700 "${VAR_ROOT}/.ssh"
        echo "    SSH authorized_keys installed for root"
    fi
    sudo umount /mnt/tromso-root-setup
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
    echo "    Logs:   tail -f /tmp/tromso-serial.log"
    echo "    Stop:   kill \$(cat /tmp/tromso-vm.pid)"
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
        -pidfile /tmp/tromso-vm.pid
