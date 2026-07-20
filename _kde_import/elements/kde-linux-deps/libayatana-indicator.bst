kind: cmake
description: Ayatana Indicators shared library

sources:
- kind: tar
  url: tar_https:github.com/AyatanaIndicators/libayatana-indicator/archive/0.9.4.tar.gz
  ref: a18d3c682e29afd77db24366f8475b26bda22b0e16ff569a2ec71cd6eb4eac95

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- sdk/gobject-introspection.bst
- sdk/vala.bst

depends:
- kde-linux-deps/ayatana-ido.bst
- sdk/glib.bst
- sdk/gtk+-3.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DENABLE_TESTS=OFF
    -DCMAKE_INSTALL_LIBEXECDIR=lib
