kind: stack

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/btrfs-progs.bst
- freedesktop-sdk.bst:components/cpio.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/fuse3.bst
- freedesktop-sdk.bst:components/linux-firmware.bst
- freedesktop-sdk.bst:components/shadow.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/tpm2-tss.bst
- freedesktop-sdk.bst:components/tpm2-tools.bst
- freedesktop-sdk.bst:components/tzdata.bst
- freedesktop-sdk.bst:components/util-linux.bst
- kde-linux-deps/plymouth-gnome-theme.bst
- kde-linux-deps/udev-hide-usr.bst
- kde-linux-deps/zram-generator.bst
- kde-linux-system/initramfs/signed-modules.bst
- kde-linux-system/reload-sysext.bst
- oci/integration/os-release.bst
- kde-linux-deps/bootc.bst
- oci/integration/lvm2-enable-activation.bst

(?):
- arch in ["x86_64"]:
    depends:
      (>):
      - kde-linux-deps/intel-ucode.bst
