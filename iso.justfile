# Output directory for built ISOs and intermediate artifacts.
# Override with: just output_dir=/your/path iso-sd-boot tromso
output_dir := "output"

# Set to 1 to enable SSH in the live session for debugging.
# Example: just debug=1 output_dir=/tmp/out iso-sd-boot tromso
# Never use debug=1 for production/release ISOs.
debug := "0"

# Set to "dev" to pull the tuna-installer dev build (continuous-dev release).
# Example: just installer_channel=dev iso-sd-boot tromso
installer_channel := "stable"

# LUKS passphrase used by luks-install for testing.
luks-passphrase := "testpassphrase"

# Squashfs compression preset:
#   fast    (default) — zstd level 3,  128K blocks — quick local builds/CI
#   release           — zstd level 15, 1M blocks   — ~20% smaller, ~5× slower
# Example: just compression=release iso-sd-boot tromso
compression := "fast"

# Build the ISO in the background, detached from the terminal session.
# Logs are written to {{output_dir}}/build.log and tailed live.
# Usage: just build-bg tromso
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

container target:
    #!/usr/bin/bash
    set -euo pipefail
    # Pre-squash base image to avoid disk explosion during multi-layer pulls
    BASE_IMAGE=$(grep '^ARG BASE_IMAGE=' ./{{target}}/Containerfile | cut -d= -f2)
    echo "Squashing base image: ${BASE_IMAGE}"
    SQUASH_CTR=$(sudo buildah from --pull-never "${BASE_IMAGE}" 2>/dev/null || sudo buildah from "${BASE_IMAGE}")
    sudo buildah commit --squash "${SQUASH_CTR}" oci-archive:/tmp/squashed-base.oci:"${BASE_IMAGE}"
    sudo podman load -i /tmp/squashed-base.oci
    rm -f /tmp/squashed-base.oci

    sudo podman build --cap-add sys_admin --security-opt label=disable \
        --layers \
        --build-arg BASE_IMAGE="${BASE_IMAGE}" \
        --build-arg DEBUG={{debug}} \
        --build-arg INSTALLER_CHANNEL={{installer_channel}} \
        -t {{target}}-installer ./{{target}}

# Build the Debian-based ISO assembly container for the given target.
iso-builder target:
    podman build --security-opt label=disable -t {{target}}-iso-builder \
        -f ./{{target}}/Containerfile.builder ./{{target}}

# Build a systemd-boot UEFI live ISO for the given target.
#
# Uses a two-container approach:
#   1. localhost/<target>-installer — the live environment (3-stage Containerfile)
#   2. localhost/<target>-iso-builder — Debian ISO assembly tools (Containerfile.builder)
#
# Output: output/<target>-live.iso
iso-sd-boot target:
    #!/usr/bin/bash
    set -euo pipefail

    # Read payload ref from file (defaults to localhost/<target>:latest if missing)
    PAYLOAD_REF="$(cat '{{target}}/payload_ref' 2>/dev/null | tr -d '[:space:]' || echo "localhost/{{target}}:latest")"

    just debug={{debug}} installer_channel={{installer_channel}} container {{target}}
    mkdir -p {{output_dir}}
    OUTPUT_DIR=$(realpath "{{output_dir}}")

    if [[ $(id -u) -eq 0 ]]; then
        _ns()    { bash -c "$1"; }
        _ns_rm() { rm -rf "$@"; }
    else
        _ns()    { podman unshare bash -c "$1"; }
        _ns_rm() { podman unshare rm -rf "$@"; }
    fi

    SQUASHFS="${OUTPUT_DIR}/{{target}}-rootfs.sfs"
    BOOT_TAR="${OUTPUT_DIR}/{{target}}-boot-files.tar"
    CS_STAGING="${OUTPUT_DIR}/{{target}}-cs-staging"
    SQUASHFS_ROOT="${OUTPUT_DIR}/{{target}}-sfs-root"
    trap "rm -f '${SQUASHFS}' '${BOOT_TAR}' '${OUTPUT_DIR}/{{target}}-payload.oci.tar'; _ns_rm '${CS_STAGING}' '${SQUASHFS_ROOT}' 2>/dev/null || true" EXIT
    echo "Building squashfs and boot tar from localhost/{{target}}-installer..."
    _ns "
        set -euo pipefail
        MOUNT=\$(podman image mount localhost/{{target}}-installer)
        PATH=/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:\$PATH

        PAYLOAD_OCI='${OUTPUT_DIR}/{{target}}-payload.oci.tar'
        CS_STAGING='${CS_STAGING}'
        SQUASHFS_ROOT='${SQUASHFS_ROOT}'
        SQUASHFS_STORAGE=\"\${CS_STAGING}/var/lib/containers/storage\"
        STORAGE_CONF=\"\$(mktemp '${OUTPUT_DIR}'/live-storage-XXXXXX.conf)\"
        mkdir -p \"\${SQUASHFS_STORAGE}\"
        printf '[storage]\ndriver = \"vfs\"\nrunroot = \"/tmp/cs-runroot\"\ngraphroot = \"/vfs-storage\"\n' \
            > \"\${STORAGE_CONF}\"

        echo 'Squashing tromso image layers to reduce disk footprint...'
        SQUASH_CTR=\$(buildah from --pull-never \"${PAYLOAD_REF}\")
        buildah commit --squash \"\${SQUASH_CTR}\" oci-archive:\${PAYLOAD_OCI}:${PAYLOAD_REF}

        echo 'Importing tromso OCI image into squashfs containers-storage...'
        podman run --rm \
            --privileged \
            -v \"\${PAYLOAD_OCI}:/payload.oci.tar:ro\" \
            -v \"\${SQUASHFS_STORAGE}:/vfs-storage\" \
            -v \"\${STORAGE_CONF}:/tmp/st.conf:ro\" \
            localhost/{{target}}-installer \
            sh -c 'mkdir -p /tmp/cs-runroot /var/tmp && CONTAINERS_STORAGE_CONF=/tmp/st.conf skopeo copy oci-archive:/payload.oci.tar:${PAYLOAD_REF} containers-storage:${PAYLOAD_REF}'

        rm -f \"\${PAYLOAD_OCI}\" \"\${STORAGE_CONF}\"

        echo 'Building unified squashfs source tree...'
        mkdir -p \"\${SQUASHFS_ROOT}\"
        cp -a --reflink=auto \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\" 2>/dev/null || \
            cp -a \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\"
        mkdir -p \"\${SQUASHFS_ROOT}/var/lib/containers/storage\"
        cp -a \"\${CS_STAGING}/var/lib/containers/storage/.\" \
            \"\${SQUASHFS_ROOT}/var/lib/containers/storage/\"
        rm -rf \"\${CS_STAGING}\"

        SFS_LEVEL=3; SFS_BLOCK=131072
        [[ '{{compression}}' == 'release' ]] && { SFS_LEVEL=15; SFS_BLOCK=1048576; }
        mksquashfs \"\${SQUASHFS_ROOT}\" '${SQUASHFS}' \
            -noappend -comp zstd -Xcompression-level \${SFS_LEVEL} -b \${SFS_BLOCK} \
            -processors 4 \
            -e proc -e sys -e dev -e run -e tmp

        rm -rf \"\${SQUASHFS_ROOT}\"

        tar -C \"\$MOUNT\" \
            -cf '${BOOT_TAR}' \
            ./usr/lib/modules \
            ./usr/lib/systemd/boot/efi
        podman image umount localhost/{{target}}-installer
    "

    TMPDIR="${OUTPUT_DIR}" \
    PATH="/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}" \
        bash "{{target}}/src/build-iso.sh" "${BOOT_TAR}" "${SQUASHFS}" "${OUTPUT_DIR}/{{target}}-live.iso"

    echo "ISO ready: ${OUTPUT_DIR}/{{target}}-live.iso"

# Boot a built ISO in QEMU via UEFI (OVMF) with serial console output on stdout.
# Exit: Ctrl-A then X
boot-iso-serial target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    ISO=$(ls \
        {{output_dir}}/{{target}}-live.iso \
        2>/dev/null | head -1 || true)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found for '{{target}}' — run: just iso-sd-boot {{target}}" >&2
        exit 1
    fi

    OVMF_CODE=""
    for f in \
        /usr/share/OVMF/OVMF_CODE.fd \
        /usr/share/edk2/ovmf/OVMF_CODE.fd \
        /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
        /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    OVMF_VARS_SRC=""
    for f in \
        /usr/share/OVMF/OVMF_VARS.fd \
        /usr/share/edk2/ovmf/OVMF_VARS.fd \
        /usr/share/edk2-ovmf/x64/OVMF_VARS.fd; do
        [[ -f "$f" ]] && { OVMF_VARS_SRC="$f"; break; }
    done
    if [[ -z "$OVMF_CODE" ]]; then
        echo "OVMF firmware not found — install edk2-ovmf or ovmf" >&2
        exit 1
    fi

    OVMF_VARS=$(mktemp /tmp/OVMF_VARS.XXXXXX.fd)
    [[ -n "$OVMF_VARS_SRC" ]] && cp "${OVMF_VARS_SRC}" "${OVMF_VARS}"
    trap "rm -f ${OVMF_VARS}" EXIT

    echo "Booting ${ISO} via UEFI — serial console below (Ctrl-A X to quit)"
    echo "SSH available on localhost:2222 (user: liveuser, password: live) if built with debug=1"
    sudo "$QEMU" \
        -machine q35 \
        -m 4096 \
        -accel kvm \
        -cpu host \
        -smp 4 \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -drive if=none,id=live-disk,file="${ISO}",media=cdrom,format=raw,readonly=on \
        -device virtio-scsi-pci,id=scsi \
        -device scsi-cd,drive=live-disk \
        -net nic,model=virtio -net user,hostfwd=tcp::2222-:22 \
        -serial mon:stdio \
        -display none \
        -no-reboot

# Boot ISO with VNC display (for seeing the Plasma desktop)
boot-iso-vnc target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    ISO=$(ls {{output_dir}}/{{target}}-live.iso 2>/dev/null | head -1 || true)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found — run: just iso-sd-boot {{target}}" >&2; exit 1
    fi

    OVMF_CODE=""
    for f in /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd \
              /usr/share/edk2-ovmf/x64/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    OVMF_VARS=$(mktemp /tmp/OVMF_VARS.XXXXXX.fd)
    for f in /usr/share/OVMF/OVMF_VARS.fd /usr/share/edk2/ovmf/OVMF_VARS.fd \
              /usr/share/edk2-ovmf/x64/OVMF_VARS.fd; do
        [[ -f "$f" ]] && { cp "$f" "${OVMF_VARS}"; break; }
    done
    [[ -z "$OVMF_CODE" ]] && { echo "OVMF firmware not found" >&2; exit 1; }
    trap "rm -f ${OVMF_VARS}" EXIT

    echo "Booting ${ISO}"
    echo "  VNC:    vncviewer 127.0.0.1:5910  (display :10)"
    echo "  Serial: telnet 127.0.0.1 4445"
    echo "  SSH:    ssh -p 2222 liveuser@127.0.0.1  (debug=1 only)"
    sudo "$QEMU" \
        -machine q35 -cpu host -m 4096 -smp 4 -accel kvm \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -drive if=none,id=live-disk,file="${ISO}",media=cdrom,format=raw,readonly=on \
        -device virtio-scsi-pci,id=scsi \
        -device scsi-cd,drive=live-disk \
        -device virtio-vga \
        -display vnc=127.0.0.1:10 \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -serial telnet:127.0.0.1:4445,server,nowait \
        -no-reboot

# ─────────────────────────────────────────────────────────────────────────────
# LUKS install end-to-end test (ported from projectbluefin/dakota-iso)
# ─────────────────────────────────────────────────────────────────────────────
#
# Full CI test sequence:
#   just debug=1 iso-sd-boot tromso
#   just luks-test-qemu tromso
#
# Or step-by-step:
#   just luks-boot-qemu-live tromso       # boot live ISO in QEMU (daemonized)
#   just luks-install-qemu tromso         # SSH fisherman install
#   just luks-boot-qemu-installed tromso  # reboot QEMU into installed disk
#   just luks-unlock-qemu tromso          # send passphrase via QEMU monitor

# Path to a local fisherman checkout for bootcDirect (ostree) installs; unused
# on the default composefs path.
fisher_repo := ""

# QEMU memory (MiB) / vCPUs for the e2e test VMs.
qemu-mem := "8192"
qemu-smp := "4"

# QEMU install disk path (override with: just luks-qemu-disk=/path/disk.qcow2 ...)
luks-qemu-disk := "/var/tmp/tromso-luks-install.qcow2"
# Scratch disk mounted over /var/tmp inside the live VM — prevents ENOSPC
# during OCI blob extraction (overlay tmpfs is small).
luks-scratch-disk := "/var/tmp/tromso-luks-scratch.img"

# QEMU monitor sockets and serial logs
luks-qemu-monitor-live := "/tmp/tromso-qemu-live.sock"
luks-qemu-monitor-installed := "/tmp/tromso-qemu-installed.sock"
luks-qemu-serial-live := "/tmp/tromso-qemu-live-serial.log"
luks-qemu-serial-installed := "/tmp/tromso-qemu-installed-serial.log"

# SSH port for QEMU SLIRP forwarding
luks-qemu-ssh-port := "2222"

# Full end-to-end test: build the ISO then run the LUKS install + boot test.
# Usage: just debug=1 e2e tromso
e2e target:
    #!/usr/bin/bash
    set -euo pipefail
    echo "=== Step 1/2: Building ISO (debug={{debug}}, installer_channel={{installer_channel}}) ==="
    just debug={{debug}} installer_channel={{installer_channel}} output_dir={{output_dir}} iso-sd-boot {{target}}
    echo "=== Step 2/2: LUKS end-to-end test ==="
    rm -f /var/tmp/tromso-luks-install-*.qcow2 /var/tmp/tromso-luks-scratch-*.img \
               "{{luks-qemu-monitor-live}}" "{{luks-qemu-monitor-installed}}" \
               "{{luks-qemu-serial-live}}" "{{luks-qemu-serial-installed}}"
    just luks-test-qemu {{target}}

# Run the full LUKS end-to-end test in QEMU (CI entry point).
# Builds nothing — expects the ISO to already exist in {{output_dir}}.
luks-test-qemu target installer_channel="stable":
    #!/usr/bin/bash
    set -euo pipefail
    DISK="/var/tmp/tromso-luks-install-{{target}}-{{installer_channel}}.qcow2"
    SCRATCH="/var/tmp/tromso-luks-scratch-{{target}}-{{installer_channel}}.img"
    just luks-qemu-disk="$DISK" luks-scratch-disk="$SCRATCH" luks-boot-qemu-live {{target}}
    just luks-qemu-ssh-port={{luks-qemu-ssh-port}} luks-install-qemu {{target}}
    just luks-qemu-disk="$DISK" luks-scratch-disk="$SCRATCH" luks-boot-qemu-installed {{target}}
    just luks-qemu-monitor-installed={{luks-qemu-monitor-installed}} \
         luks-qemu-serial-installed={{luks-qemu-serial-installed}} \
         luks-unlock-qemu {{target}}

# Boot the live ISO in QEMU (daemonized) with a blank install disk attached.
luks-boot-qemu-live target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    ISO=$(ls {{output_dir}}/{{target}}-live.iso 2>/dev/null | head -1 || true)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found — run: just debug=1 iso-sd-boot {{target}}" >&2
        exit 1
    fi

    OVMF_CODE=""; OVMF_VARS=""
    for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
              /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    for f in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd \
              /usr/share/edk2/ovmf/OVMF_VARS.fd; do
        if [[ -f "$f" ]]; then cp "$f" /var/tmp/tromso-qemu-live-vars.fd; OVMF_VARS=/var/tmp/tromso-qemu-live-vars.fd; break; fi
    done
    [[ -z "$OVMF_CODE" ]] && { echo "OVMF firmware not found" >&2; exit 1; }

    [[ -f "{{luks-qemu-disk}}" ]] || qemu-img create -f qcow2 "{{luks-qemu-disk}}" 64G
    [[ -f "{{luks-scratch-disk}}" ]] || truncate -s 16G "{{luks-scratch-disk}}"
    rm -f "{{luks-qemu-monitor-live}}" "{{luks-qemu-serial-live}}"

    echo "Booting live ISO: $ISO"
    # KVM access: try direct, then sudo, then fall back to TCG
    QEMU_ACCEL="-accel kvm"
    QEMU_PREFIX=""
    if ! test -r /dev/kvm 2>/dev/null; then
        if sudo test -r /dev/kvm 2>/dev/null; then
            echo "Using sudo for KVM access"
            QEMU_PREFIX="sudo"
        else
            echo "KVM not available, falling back to TCG emulation (slower)"
            QEMU_ACCEL="-accel tcg,thread=multi"
            QEMU_PREFIX=""
        fi
    fi
    CPU_FLAG="-cpu host"
    if [[ "$QEMU_ACCEL" =~ tcg ]]; then
        CPU_FLAG="-cpu qemu64"
    fi
    $QEMU_PREFIX "$QEMU" \
        -machine q35 $CPU_FLAG -m {{qemu-mem}} -smp {{qemu-smp}} $QEMU_ACCEL \
        -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}" \
        -drive "if=pflash,format=raw,file=${OVMF_VARS}" \
        -drive "if=none,id=iso,file=${ISO},media=cdrom,readonly=on,format=raw" \
        -device virtio-scsi-pci,id=scsi \
        -device scsi-cd,drive=iso \
        -drive "if=none,id=disk,file={{luks-qemu-disk}},format=qcow2" \
        -device virtio-blk-pci,drive=disk \
        -drive "if=none,id=scratch,file={{luks-scratch-disk}},format=raw,cache=unsafe" \
        -device virtio-blk-pci,drive=scratch \
        -netdev "user,id=net0,hostfwd=tcp::{{luks-qemu-ssh-port}}-:22" \
        -device virtio-net-pci,netdev=net0 \
        -monitor "unix:{{luks-qemu-monitor-live}},server,nowait" \
        -serial "file:{{luks-qemu-serial-live}}" \
        -display none \
        -daemonize
    echo "Live QEMU started (monitor: {{luks-qemu-monitor-live}})"

    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 -o PreferredAuthentications=password"
    echo "Waiting for live environment on port {{luks-qemu-ssh-port}}..."
    # Ready when the serial marker appears OR SSH connects (debug=1 builds).
    for i in $(seq 1 60); do
        if grep -q "TROMSO_LIVE_READY" "{{luks-qemu-serial-live}}" 2>/dev/null; then
            echo "Live environment ready (serial marker seen)"
            break
        fi
        if sshpass -p live ssh $SSH_OPTS liveuser@127.0.0.1 -p {{luks-qemu-ssh-port}} true 2>/dev/null; then
            echo "Live environment ready (SSH connected)"
            break
        fi
        [[ "$i" -eq 60 ]] && { echo "ERROR: live env not ready after 5m"; tail -30 "{{luks-qemu-serial-live}}" || true; exit 1; }
        sleep 5
    done

    # Wait for the live boot GUI to render and stabilize before screenshotting
    sudo python3 "{{target}}/src/luks-unlock.py" wait-live \
        "{{luks-qemu-monitor-live}}" \
        "/tmp/luks-screenshot-live.ppm" || true

# Run fisherman LUKS install via SSH into the live QEMU VM.
luks-install-qemu target:
    ./scripts/luks-install-qemu.sh "{{target}}" "{{luks-passphrase}}" "{{luks-qemu-ssh-port}}" "{{luks-qemu-monitor-live}}" "{{fisher_repo}}"

# Boot the installed disk in QEMU (no ISO). Called after luks-install-qemu.
luks-boot-qemu-installed target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    OVMF_CODE=""; OVMF_VARS=""
    for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
              /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    for f in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd \
              /usr/share/edk2/ovmf/OVMF_VARS.fd; do
        if [[ -f "$f" ]]; then cp "$f" /var/tmp/tromso-qemu-installed-vars.fd; OVMF_VARS=/var/tmp/tromso-qemu-installed-vars.fd; break; fi
    done
    [[ -z "$OVMF_CODE" ]] && { echo "OVMF firmware not found" >&2; exit 1; }

    rm -f "{{luks-qemu-monitor-installed}}" "{{luks-qemu-serial-installed}}"

    echo "Booting installed disk: {{luks-qemu-disk}}"
    # Wait for the live QEMU holding this disk to exit before rebooting it.
    DISK_PATTERN="$(echo '{{luks-qemu-disk}}' | sed 's/\./\\./g')"
    for i in {1..15}; do
        if ! sudo pgrep -f "qemu-system.*${DISK_PATTERN}" >/dev/null 2>&1; then
            break
        fi
        echo "Waiting for live QEMU to exit (attempt $i)..."
        sleep 2
    done
    QEMU_ACCEL="-accel kvm"
    QEMU_PREFIX=""
    if ! test -r /dev/kvm 2>/dev/null; then
        if sudo test -r /dev/kvm 2>/dev/null; then
            echo "Using sudo for KVM access"
            QEMU_PREFIX="sudo"
        else
            echo "KVM not available, falling back to TCG emulation (slower)"
            QEMU_ACCEL="-accel tcg,thread=multi"
            QEMU_PREFIX=""
        fi
    fi
    CPU_FLAG="-cpu host"
    if [[ "$QEMU_ACCEL" =~ tcg ]]; then
        CPU_FLAG="-cpu qemu64"
    fi
    $QEMU_PREFIX "$QEMU" \
        -machine q35 $CPU_FLAG -m {{qemu-mem}} -smp {{qemu-smp}} $QEMU_ACCEL \
        -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}" \
        -drive "if=pflash,format=raw,file=${OVMF_VARS}" \
        -drive "if=none,id=disk,file={{luks-qemu-disk}},format=qcow2" \
        -device virtio-blk-pci,drive=disk \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
        -monitor "unix:{{luks-qemu-monitor-installed}},server,nowait" \
        -serial "file:{{luks-qemu-serial-installed}}" \
        -display none \
        -daemonize
    echo "Installed QEMU started (monitor: {{luks-qemu-monitor-installed}})"

    for i in $(seq 1 15); do
        [[ -S "{{luks-qemu-monitor-installed}}" ]] && break
        sleep 2
    done

# Send LUKS passphrase to installed QEMU VM via monitor screendump + sendkey.
# Polls screendump size to detect Plymouth takeover, then injects keystrokes.
luks-unlock-qemu target:
    #!/usr/bin/bash
    set -euo pipefail
    PASSPHRASE="{{luks-passphrase}}"
    echo "Unlocking LUKS on installed QEMU VM..."
    sudo python3 "{{target}}/src/luks-unlock.py" qemu \
        "{{luks-qemu-monitor-installed}}" \
        "$PASSPHRASE" \
        "{{luks-qemu-serial-installed}}"

    # Show key screenshots inline for terminals that support it (Kitty, iTerm2)
    bash "{{target}}/src/show-screenshot.sh" /tmp/luks-screenshot-plymouth.ppm "Plymouth prompt" || true
    bash "{{target}}/src/show-screenshot.sh" /tmp/luks-screenshot-final.ppm "Final boot" || true
