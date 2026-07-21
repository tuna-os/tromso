kind: cmake
description: Ayatana Indicator Display Objects (GTK3 widget library for indicators)

sources:
- kind: tar
  url: tar_https:github.com/AyatanaIndicators/ayatana-ido/archive/0.10.4.tar.gz
  ref: bd59abd5f1314e411d0d55ce3643e91cef633271f58126be529de5fb71c5ab38

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- sdk/gobject-introspection.bst
- sdk/vala.bst

depends:
- sdk/gtk+-3.bst
- sdk/glib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DENABLE_TESTS=OFF
