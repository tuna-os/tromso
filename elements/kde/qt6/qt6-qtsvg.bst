kind: cmake
description: Qt6 SVG module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DINSTALL_ARCHDATADIR=lib

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtsvg-everywhere-src-6.10.3.tar.xz
  ref: b3223fe005f6a4c7f21f34e4ee6ce0094737cff9503ba15bbb171ac18794f76d
