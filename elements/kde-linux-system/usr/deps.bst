kind: stack

depends:
- kde-linux-deps/deps.bst

- kde-linux-system/repart-config.bst
- kde-linux-system/initramfs/signed-modules.bst
- kde-linux-system/sysupdate-config.bst
- kde-linux-system/import-deployment-pub-key.bst
- kde-linux-system/os-release.bst
- kde-linux-system/fwupd-efi-signed-maybe.bst
- kde-linux-system/replace-signed-systemd-boot.bst
- kde-linux-system/reload-sysext.bst
- kde-linux-system/live.bst
- kde-linux-system/systemd-pcrlock-workaround.bst
- kde-linux-system/public-keys.bst
- kde-linux-system/signed-boot-common.bst
- freedesktop-sdk.bst:vm/config/useradd-default.bst
- kde-linux-system/confext.bst
- kde-linux-system/binfmt-from-sysext.bst

(?):
- arch in ["x86_64"]:
    depends:
      (>):
      - kde-linux-system/sysupdate-nvidia-config.bst
