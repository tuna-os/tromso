kind: cmake
description: Qt6 speech module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-qtmultimedia.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtspeech-everywhere-src-6.10.3.tar.xz
  ref: 6616e435bd6069aac4357cd35f7cb6c01a77e804fa57c5f58d8b8031f2036c1d
