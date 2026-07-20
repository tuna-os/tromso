BINARIES=(
    btrfs
    btrfsck
    mkfs.btrfs
    fsck
    fsck.btrfs
    dmsetup
    xfs_repair
    xfs_db
    xfs_growfs
    fsck.xfs
    mkfs.xfs
)

install() {
    for b in "${BINARIES[@]}"; do
        if [ -f "/usr/bin/${b}" ]; then
            install_file "/usr/bin/${b}"
        elif [ -f "/usr/sbin/${b}" ]; then
            install_file "/usr/sbin/${b}"
        fi
    done

    install_file_at_path "${moddir}/systemd-udev-trigger-btrfs.conf" "/usr/lib/systemd/system/systemd-udev-trigger.service.d/btrfs.conf"
    systemctl -q --root "${root}" add-wants sysinit.target modprobe@btrfs.service
    systemctl -q --root "${root}" add-wants sysinit.target modprobe@xfs.service
}
