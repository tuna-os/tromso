kind: cmake
description: Qt6 image formats module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtimageformats-everywhere-src-6.10.3.tar.xz
  ref: 84605dd91037482b5b7c7ecc5c27aee8acc1cd7f1fe77bc564777ddf365d7d28
