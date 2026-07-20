kind: cmake
description: qt6-qtquick3dphysics

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtquick3dphysics-everywhere-src-6.10.3.tar.xz
  ref: 2abbc8e32df6d8f7e7ba5341c8032054459b95ff3b0c9601f61666931a10f5f6
