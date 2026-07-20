kind: cmake
description: Qt6 Qt5 compatibility module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qt5compat-everywhere-src-6.10.3.tar.xz
  ref: 60e8980a8eaedd65a6e4092e8acbbec61aa50ce907d0a69a1e52ad256373d3f4
