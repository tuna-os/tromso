kind: autotools
description: libfakekey - X virtual keyboard library

sources:
- kind: tar
  url: github:veyon/libfakekey/archive/refs/tags/0.3.tar.gz
  ref: d282fa6481a5b85f71e36e8bad4cfa938cc8eaac4c42ffa27f9203ac634813f4

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/xorg-lib-xtst.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  configure-args: >-
    --disable-static
    --disable-silent-rules
