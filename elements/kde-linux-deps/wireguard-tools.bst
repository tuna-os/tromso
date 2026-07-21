kind: make
description: WireGuard tools - wg and wg-quick utilities

sources:
- kind: tar
  url: tar_https:git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-1.0.20210914.tar.xz
  ref: 942ed32d1d6631932c82ff86c91ae8428d4c90bfec231a14ebdf6c29f068e60b

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/pkg-config.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  make-args: >-
    -C src
    WITH_WGQUICK=yes
    WITH_BASHCOMPLETION=no
    WITH_SYSTEMDUNITS=yes
    PREFIX="%{prefix}"
    SYSCONFDIR="%{sysconfdir}"
    RUNSTATEDIR="/run"
  make-install-args: >-
    -C src
    WITH_WGQUICK=yes
    WITH_BASHCOMPLETION=no
    WITH_SYSTEMDUNITS=yes
    PREFIX="%{prefix}"
    SYSCONFDIR="%{sysconfdir}"
    RUNSTATEDIR="/run"
