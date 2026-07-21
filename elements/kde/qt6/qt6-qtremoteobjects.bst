kind: cmake
description: qt6-qtremoteobjects

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtremoteobjects-everywhere-src-6.10.3.tar.xz
  ref: fa8faa42fbc4c97ef087cd7e0e7b6f21288d66498113a3f5bc3681cf798d5968
