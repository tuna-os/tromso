output_dir := "output"
workdir := output_dir
debug := "0"
installer_channel := "stable"
compression := "fast"

# Create an XFS loopback mount at /mnt for faster VFS import.
# Idempotent: skips if /mnt is already an XFS mount.
# Must be run as root: sudo just mount-xfs
mount-xfs:
    #!/usr/bin/bash
    set -euo pipefail
    if findmnt -n -o FSTYPE /mnt 2>/dev/null | grep -q '^xfs$'; then
        echo "/mnt is already XFS — skipping"
        exit 0
    fi
    echo "Creating 45G XFS loopback at /mnt..."
    IMG="/var/tmp/tromso-xfs-loopback.img"
    truncate -s 0 "${IMG}"
    chattr +C "${IMG}" 2>/dev/null || true
    fallocate -l 45G "${IMG}"
    mkfs.xfs -f "${IMG}"
    mount -o loop "${IMG}" /mnt
    echo "XFS mounted at /mnt (45G)"
    echo ""
    echo "Now run your build with workdir on /mnt:"
    echo "  sudo just workdir=/mnt iso-sd-boot tromso"
    echo "To run rootless (replace \`user\` with your username):"
    echo "  sudo chown user:user /mnt && just workdir=/mnt iso-sd-boot tromso"
    df -h /mnt

# Build the ISO in the background, detached from the terminal session.
build-bg target:
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p {{output_dir}}
    LOG=$(realpath {{output_dir}})/build.log
    echo "Starting background build → ${LOG}"
    setsid sudo just \
        debug={{debug}} \
        installer_channel={{installer_channel}} \
        output_dir={{output_dir}} \
        compression={{compression}} \
        iso-sd-boot {{target}} \
        > "${LOG}" 2>&1 &
    disown $!
    echo "Build PID $! — tailing log (Ctrl-C is safe, build continues)"
    tail -f "${LOG}"

_payload_ref_flag target:
    @if [ -f "{{target}}/payload_ref" ]; then echo "--bootc-installer-payload-ref $(cat '{{target}}/payload_ref' | tr -d '[:space:]')"; fi

container target:
    @test -f "{{target}}/payload_ref" || { echo "ERROR: {{target}}/payload_ref not found"; exit 1; }
    podman build --cap-add sys_admin --security-opt label=disable \
        --layers \
        --build-arg DEBUG={{debug}} \
        --build-arg INSTALLER_CHANNEL={{installer_channel}} \
        --build-arg BASE_IMAGE=$(cat {{target}}/payload_ref | tr -d '[:space:]') \
        -t {{target}}-installer -f ./{{target}}/Containerfile ./{{target}}

iso-builder target:
    podman build --security-opt label=disable -t {{target}}-iso-builder \
        -f ./{{target}}/Containerfile.builder ./{{target}}

# Build a systemd-boot UEFI live ISO for the given target.
# Output: output/<target>-live.iso
iso-sd-boot target:
    #!/usr/bin/bash
    set -euo pipefail
    PAYLOAD_IMAGE=$(cat "{{target}}/payload_ref" | tr -d '[:space:]')

    mkdir -p {{output_dir}}
    OUTPUT_DIR=$(realpath "{{output_dir}}")
    WORKDIR=$(realpath "{{workdir}}")

    echo "=== Disk space before container build ==="
    df -h "${OUTPUT_DIR}"

    AVAILABLE_KB=$(df --output=avail -B1024 "${OUTPUT_DIR}" | tail -1 | tr -d ' ')
    REQUIRED_KB=$((20 * 1024 * 1024))
    if [ "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]; then
        echo "WARNING: Only $(( AVAILABLE_KB / 1024 / 1024 ))GB free — ISO build needs ~20GB" >&2
    fi

    just debug={{debug}} installer_channel={{installer_channel}} container {{target}}

    echo "=== Disk space after container build ==="
    df -h "${OUTPUT_DIR}"

    podman rmi debian:sid 2>/dev/null || true
    podman image prune -f 2>/dev/null || true

    if [[ $(id -u) -eq 0 ]]; then
        _ns()    { bash -c "$1"; }
    else
        _ns()    { podman unshare bash -c "$1"; }
    fi

    SQUASHFS="${OUTPUT_DIR}/{{target}}-rootfs.sfs"
    BOOT_TAR="${OUTPUT_DIR}/{{target}}-boot-files.tar"
    CS_STAGING="${WORKDIR}/{{target}}-cs-staging"
    SQUASHFS_ROOT="${WORKDIR}/{{target}}-sfs-root"
    trap "rm -f '${SQUASHFS}' '${BOOT_TAR}' '${OUTPUT_DIR}/{{target}}-payload.oci.tar' 2>/dev/null || true" EXIT

    _ns "
        set -euo pipefail

        SQUASHFS_ROOT='${SQUASHFS_ROOT}'
        CS_STAGING='${CS_STAGING}'
        OVERLAY_UPPER=\$(mktemp -d \"\${SQUASHFS_ROOT}_upper_XXXXXX\")
        OVERLAY_WORK=\$(mktemp -d \"\${SQUASHFS_ROOT}_work_XXXXXX\")

        ns_cleanup() {
            umount \"\${SQUASHFS_ROOT}/var/lib/containers/storage\" 2>/dev/null || true
            umount \"\${SQUASHFS_ROOT}\"                            2>/dev/null || true
            podman image unmount localhost/{{target}}-installer     2>/dev/null || true
            rm -rf \"\${OVERLAY_UPPER}\" \"\${OVERLAY_WORK}\"       2>/dev/null || true
            rm -rf \"\${CS_STAGING}\" \"\${SQUASHFS_ROOT}\"         2>/dev/null || true
        }
        trap ns_cleanup EXIT

        MOUNT=\$(podman image mount localhost/{{target}}-installer)
        PATH=/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:\$PATH

        PAYLOAD_OCI='${OUTPUT_DIR}/{{target}}-payload.oci.tar'
        SQUASHFS_STORAGE=\"\${CS_STAGING}/var/lib/containers/storage\"
        STORAGE_CONF=\"\$(mktemp '${OUTPUT_DIR}'/live-storage-XXXXXX.conf)\"
        mkdir -p \"\${SQUASHFS_STORAGE}\"
        printf '[storage]\ndriver = \"vfs\"\nrunroot = \"/tmp/cs-runroot\"\ngraphroot = \"/vfs-storage\"\n' \
            > \"\${STORAGE_CONF}\"

        echo 'Exporting OCI image to archive...'
        skopeo copy containers-storage:'"${PAYLOAD_IMAGE}"' oci-archive:\${PAYLOAD_OCI}:'"${PAYLOAD_IMAGE}"'
        podman rmi '"${PAYLOAD_IMAGE}"' || true

        echo 'Importing Tromso OCI image into squashfs containers-storage...'
        podman run --rm \
            --privileged \
            -v \"\${PAYLOAD_OCI}:/payload.oci.tar:ro\" \
            -v \"\${SQUASHFS_STORAGE}:/vfs-storage\" \
            -v \"\${STORAGE_CONF}:/tmp/st.conf:ro\" \
            localhost/{{target}}-installer \
            sh -c 'mkdir -p /tmp/cs-runroot /var/tmp && CONTAINERS_STORAGE_CONF=/tmp/st.conf skopeo copy oci-archive:/payload.oci.tar:'"${PAYLOAD_IMAGE}"' containers-storage:'"${PAYLOAD_IMAGE}"''

        rm -f \"\${PAYLOAD_OCI}\" \"\${STORAGE_CONF}\"

        echo 'Building unified squashfs source tree using bind mounts...'
        mkdir -p \"\${SQUASHFS_ROOT}\"

        FS_TYPE=\$(findmnt -n -o FSTYPE -T \"\${SQUASHFS_ROOT}\" 2>/dev/null || echo \"unknown\")
        if [[ \"\${FS_TYPE}\" == \"xfs\" || \"\${FS_TYPE}\" == \"ext4\" ]]; then
            if ! mount -t overlay overlay \
                -o lowerdir=\"\${MOUNT}\",upperdir=\"\${OVERLAY_UPPER}\",workdir=\"\${OVERLAY_WORK}\" \"\${SQUASHFS_ROOT}\"; then
                cp -a \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\"
            fi
        else
            cp -a \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\"
        fi

        mkdir -p \"\${SQUASHFS_ROOT}/var/lib/containers/storage\"
        mount --bind \"\${CS_STAGING}/var/lib/containers/storage\" \"\${SQUASHFS_ROOT}/var/lib/containers/storage\"

        SFS_LEVEL=3; SFS_BLOCK=131072
        [[ '{{compression}}' == 'release' ]] && { SFS_LEVEL=15; SFS_BLOCK=1048576; }
        mksquashfs \"\${SQUASHFS_ROOT}\" '${SQUASHFS}' \
            -noappend -comp zstd -Xcompression-level \${SFS_LEVEL} -b \${SFS_BLOCK} \
            -processors 4 \
            -e proc -e sys -e dev -e run -e tmp

        tar -C \"\$MOUNT\" \
            -cf '${BOOT_TAR}' \
            ./usr/lib/modules \
            ./usr/lib/systemd/boot/efi
    "

    echo "=== Disk space after squashfs, before ISO assembly ==="
    df -h "${OUTPUT_DIR}"

    TMPDIR="${OUTPUT_DIR}" \
    PATH="/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}" \
        bash "{{target}}/src/build-iso.sh" "${BOOT_TAR}" "${SQUASHFS}" "${OUTPUT_DIR}/{{target}}-live.iso"

    echo "ISO ready: ${OUTPUT_DIR}/{{target}}-live.iso"
