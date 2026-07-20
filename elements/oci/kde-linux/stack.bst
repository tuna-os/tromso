kind: stack

depends:
# Custom versions of os-release and useradd — must come BEFORE kde/deps.bst
- oci/integration/os-release.bst
- freedesktop-sdk.bst:vm/config/useradd-ostree.bst
- kde/deps.bst

# OS-related config (reused from gnomeos, not KDE-specific)
- kde-linux-system/fwupd-efi-signed-maybe.bst
- kde-linux-system/import-deployment-pub-key.bst
- kde-linux-system/public-keys.bst
- kde-linux-system/reload-sysext.bst
# replace-signed-systemd-boot.bst dropped: local stripped-down version
# (no signing) duplicates files already provided by core-deps/systemd.bst
- kde-linux-system/systemd-pcrlock-workaround.bst

# Add the kernel
- freedesktop-sdk.bst:components/linux-firmware.bst
- freedesktop-sdk.bst:bootstrap/libselinux.bst
- kde-linux-system/initramfs/signed-modules.bst
- oci/initramfs.bst

# bootc for image-based updates
- kde-linux-deps/bootc.bst

- oci/integration/bootc-config.bst
- freedesktop-sdk.bst:vm/config/sudo-nopasswd.bst

- oci/integration/lvm2-enable-activation.bst

public:
  bst:
    integration-commands:
    # Required for bootc to create the image
    - mkdir -p /boot
    - mkdir -p /sysroot
    - mkdir -p /sysroot/ostree
    # This needs to be a relative symlink
    # for some reason
    - ln -s sysroot/ostree ostree

    - rm --verbose --recursive --force /root
    # These also get created by 10-bootc.conf tmpfiles
    # but we need them to exist for the OCI image to
    # be usable as a container as well
    - mkdir -p /var/home
    - mkdir -p /var/roothome
    - mkdir -p /var/opt
    - mkdir -p /var/mnt

    - ln -s /var/home /home
    - ln -s /var/roothome /root
    - ln -s /var/opt /opt
    - ln -s /var/mnt /mnt

    - touch /etc/machine-id
    # Remove non-.ko files from /lib/modules (depmod cleanup)
    - sh -c 'for f in /lib/modules/*/*.json /lib/modules/*/*.so /lib/modules/*/*.a; do rm -f "$f"; done'
    # Restore sudo setuid bit (lost during composefs layer composition)
    - chmod u+s /usr/bin/sudo || true
