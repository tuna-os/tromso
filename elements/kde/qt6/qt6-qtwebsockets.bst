kind: cmake
description: Qt6 websockets module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtwebsockets-everywhere-src-6.10.3.tar.xz
  ref: 6ed8196002af15ca930b4ad111f1c19ed2941f4020759dbefb23e655ef6a33a1
