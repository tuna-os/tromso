kind: stack
description: Aurora OCI image stack

depends:
  - aurora/deps.bst
  - oci/os-release.bst

  # Boot & security infrastructure (from gnomeos, not GNOME-specific)
  - kde-build-meta.bst:gnomeos/fwupd-efi-signed-maybe.bst
  - kde-build-meta.bst:gnomeos/import-deployment-pub-key.bst
  - kde-build-meta.bst:gnomeos/public-keys.bst
  - kde-build-meta.bst:gnomeos/reload-sysext.bst
  - kde-build-meta.bst:gnomeos/replace-signed-systemd-boot.bst
  - kde-build-meta.bst:gnomeos/systemd-pcrlock-workaround.bst

  # Kernel modules & initramfs
  - kde-build-meta.bst:gnomeos/initramfs/signed-modules.bst
  - kde-build-meta.bst:oci/initramfs.bst

  # Essential OCI infrastructure
  - kde-build-meta.bst:oci/integration/bootc-config.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:vm/config/useradd-ostree.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:vm/config/sudo-nopasswd.bst
  - kde-build-meta.bst:oci/integration/lvm2-enable-activation.bst

public:
  bst:
    integration-commands:
      # Required for bootc to create the image
      - mkdir -p /boot /sysroot /sysroot/ostree /etc/ostree/remotes.d
      # This needs to be a relative symlink
      - ln -s sysroot/ostree ostree

      # Wipe /var (may contain build-time state) and recreate FHS symlinks
      - rm -rfv /home /root /opt /mnt /srv /var
      - mkdir -p /var/home /var/roothome /var/opt /var/mnt /var/srv /var/tmp
      - ln -s var/home /home
      - ln -s var/roothome /root
      - ln -s var/opt /opt
      - ln -s var/mnt /mnt
      - ln -s var/srv /srv

      - touch /etc/machine-id
