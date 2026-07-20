kind: autotools
description: Library for communicating with iOS devices over USB

sources:
- kind: git_repo
  url: github:libimobiledevice/libimobiledevice.git
  track: "1.3.0"
  ref: 1.3.0-0-g15f8652126664e3a4b980e5d1c039b9053ce8566

variables:
  autogen: |
    echo "1.3.0" > .tarball-version
    autoreconf -ivf
  conf-local: >-
    --without-cython
    --disable-openssl

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- kde-linux-deps/libplist.bst
- kde-linux-deps/libusbmuxd.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-linux-deps/libplist.bst
- kde-linux-deps/libusbmuxd.bst
- freedesktop-sdk.bst:components/gnutls.bst
- freedesktop-sdk.bst:components/libgcrypt.bst

environment:
  PKG_CONFIG_PATH: /usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
