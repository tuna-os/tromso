kind: cmake
description: qt6-qtlanguageserver

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtlanguageserver-everywhere-src-6.10.3.tar.xz
  ref: 94f90484be8e49d3eb3bfcf0ba6cb2d8a170fc831c78de138332feebdf193964
