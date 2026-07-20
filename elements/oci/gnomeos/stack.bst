kind: stack

depends:
# Custom versions of os-release and useradd — must come BEFORE kde-linux-deps/deps.bst
# (which now has them removed to avoid conflicts)
- oci/integration/os-release.bst
- freedesktop-sdk.bst:vm/config/useradd-ostree.bst
- kde-linux-deps/deps.bst

# OS-related config
- kde-linux-system/fwupd-efi-signed-maybe.bst
- kde-linux-system/import-deployment-pub-key.bst
- kde-linux-system/public-keys.bst
- kde-linux-system/reload-sysext.bst
- kde-linux-system/replace-signed-systemd-boot.bst
- kde-linux-system/systemd-pcrlock-workaround.bst

# Add the kernel
- freedesktop-sdk.bst:components/linux-firmware.bst
- kde-linux-system/initramfs/signed-modules.bst
- oci/initramfs.bst

# Currently only in -devel
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
