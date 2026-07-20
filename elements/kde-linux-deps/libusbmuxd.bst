kind: autotools
description: USB multiplexing daemon client library for iOS/iPadOS devices

sources:
- kind: git_repo
  url: github:libimobiledevice/libusbmuxd.git
  track: "2.0.2"
  ref: 2.0.2-0-gce98c346b7c1dc2a21faea4fd3f32c88e27ca2af

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- kde-linux-deps/libplist.bst

depends:
- kde-linux-deps/libplist.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

environment:
  PKG_CONFIG_PATH: /usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
