kind: stack

depends:
# Custom versions of os-release and useradd — must come BEFORE kde/deps.bst
- oci/integration/os-release.bst
- freedesktop-sdk.bst:vm/config/useradd-ostree.bst
- freedesktop-sdk.bst:components/composefs.bst
- kde/deps.bst

# OS-related config (reused from gnomeos, not KDE-specific)
- kde-linux-system/fwupd-efi-signed-maybe.bst
- kde-linux-system/import-deployment-pub-key.bst
- kde-linux-system/public-keys.bst
- kde-linux-system/reload-sysext.bst
- kde-linux-system/replace-signed-systemd-boot.bst
- kde-linux-system/systemd-pcrlock-workaround.bst

# Add the kernel
- freedesktop-sdk.bst:components/linux.bst
- freedesktop-sdk.bst:components/linux-firmware.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:bootstrap/libselinux.bst
- kde-linux-system/initramfs/signed-modules.bst
- oci/initramfs.bst

# bootc for image-based updates
- kde-linux-deps/bootc.bst
- oci/integration/bootc-config.bst
- freedesktop-sdk.bst:components/ostree.bst
- freedesktop-sdk.bst:components/composefs.bst

- freedesktop-sdk.bst:vm/config/sudo-nopasswd.bst

- oci/integration/lvm2-enable-activation.bst

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
