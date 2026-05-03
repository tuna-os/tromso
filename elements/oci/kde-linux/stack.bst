kind: stack

depends:
# Custom versions of os-release and useradd — must come BEFORE kde-build-meta.bst:kde/deps.bst
- kde-build-meta.bst:oci/integration/os-release.bst
- kde-build-meta.bst:freedesktop-sdk.bst:vm/config/useradd-ostree.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/composefs.bst
- kde-build-meta.bst:kde/deps.bst

# OS-related config (reused from gnomeos, not KDE-specific)
- kde-build-meta.bst:gnomeos/fwupd-efi-signed-maybe.bst
- kde-build-meta.bst:gnomeos/import-deployment-pub-key.bst
- kde-build-meta.bst:gnomeos/public-keys.bst
- kde-build-meta.bst:gnomeos/reload-sysext.bst
- kde-build-meta.bst:gnomeos/replace-signed-systemd-boot.bst
- kde-build-meta.bst:gnomeos/systemd-pcrlock-workaround.bst

# Add the kernel
- kde-build-meta.bst:freedesktop-sdk.bst:components/linux.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/linux-firmware.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/systemd.bst
- kde-build-meta.bst:freedesktop-sdk.bst:bootstrap/libselinux.bst
- kde-build-meta.bst:gnomeos/initramfs/signed-modules.bst
- kde-build-meta.bst:oci/initramfs.bst

# bootc for image-based updates
- kde-build-meta.bst:gnomeos-deps/bootc.bst
- kde-build-meta.bst:oci/integration/bootc-config.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/ostree.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/composefs.bst

- kde-build-meta.bst:freedesktop-sdk.bst:vm/config/sudo-nopasswd.bst

- kde-build-meta.bst:oci/integration/lvm2-enable-activation.bst

public:
  bst:
    integration-commands:
    - mkdir -p /boot
    - mkdir -p /sysroot
    - mkdir -p /sysroot/ostree
    - ln -s sysroot/ostree ostree

    - rm --verbose --recursive --force /root
    - mkdir -p /var/home
    - mkdir -p /var/roothome
    - mkdir -p /var/opt
    - mkdir -p /var/mnt

    - ln -s /var/home /home
    - ln -s /var/roothome /root
    - ln -s /var/opt /opt
    - ln -s /var/mnt /mnt

    - touch /etc/machine-id
    # Remove non-module files that make depmod interpret their names as kernel versions.
    - sh -c 'for f in /lib/modules/*/*.json /lib/modules/*/*.so /lib/modules/*/*.a; do rm -f "$f"; done'
    # Restore sudo's setuid bit in the final composed image.
    - chmod u+s /usr/bin/sudo || true
    # Match Arch's kwin packaging so the greeter compositor can request realtime priority.
    - setcap cap_sys_nice+ep /usr/bin/kwin_wayland
