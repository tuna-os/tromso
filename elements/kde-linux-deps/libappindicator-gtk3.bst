kind: cmake
description: Ayatana Application Indicators shared library (libappindicator-gtk3)

sources:
- kind: tar
  url: tar_https:github.com/AyatanaIndicators/libayatana-appindicator/archive/refs/tags/0.5.94.tar.gz
  ref: 884a6bc77994c0b58c961613ca4c4b974dc91aa0f804e70e92f38a542d0d0f90

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- sdk/gobject-introspection.bst
- sdk/vala.bst

depends:
- kde-linux-deps/libayatana-indicator.bst
- kde-linux-deps/libdbusmenu-gtk3.bst
- sdk/gtk+-3.bst
- sdk/glib.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DENABLE_TESTS=OFF
    -DENABLE_BINDINGS_MONO=OFF
