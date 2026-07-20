kind: autotools
description: PC/SC driver for ACS USB CCID smart card readers

sources:
- kind: git_repo
  url: github:acshk/acsccid.git
  track: v1.1.13
  ref: ac96e83057072ba1af30a6b40e62919f5095f9d4

variables:
  autogen: |
    echo "1.1.13" > .tarball-version
    mkdir -p config
    cp /usr/share/gettext/config.rpath config/
    autoreconf -ivf

environment:
  ACLOCAL_PATH: /usr/share/gettext/m4

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gettext.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/pcsc-lite.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/pcsc-lite.bst
