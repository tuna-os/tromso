kind: cmake
description: Qt6 shader tools module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtshadertools-everywhere-src-6.10.3.tar.xz
  ref: c75837e2ea493ec0b9747b227c455d4a12cafe90068abf607992da9a403616c6
