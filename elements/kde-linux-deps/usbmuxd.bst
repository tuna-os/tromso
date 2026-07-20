kind: autotools
description: USB multiplexor daemon for iOS/iPadOS device connections

sources:
- kind: git_repo
  url: github:libimobiledevice/usbmuxd.git
  track: "1.1.1"
  ref: 79c8b38d1488a6b07e1e68f39d8caec3f1a45622

variables:
  autogen: |
    echo "1.1.1" > .tarball-version
    autoreconf -ivf

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- kde-linux-deps/libplist.bst
- kde-linux-deps/libusbmuxd.bst
- kde-linux-deps/libimobiledevice.bst
- freedesktop-sdk.bst:components/libusb.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-linux-deps/libplist.bst
- kde-linux-deps/libusbmuxd.bst
- kde-linux-deps/libimobiledevice.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/systemd.bst

environment:
  PKG_CONFIG_PATH: /usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
