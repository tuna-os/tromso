kind: manual
description: Use YubiKey to unlock LUKS encrypted partitions

sources:
- kind: tar
  url: github_files:agherzan/yubikey-full-disk-encryption/archive/dcaac005b10eac132ac663c268318bd909bf027c.tar.gz
  ref: 5059554e72c9b34b6b3caf90252ff74aeba68ab86bfd843f8ce79d1b72b223bb

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- kde-linux-deps/yubikey-personalization.bst
- freedesktop-sdk.bst:components/cryptsetup.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-linux-deps/yubikey-personalization.bst
- freedesktop-sdk.bst:components/cryptsetup.bst

config:
  build-commands: []
  install-commands:
  - make DESTDIR="%{install-root}" PREFIX=/usr install
