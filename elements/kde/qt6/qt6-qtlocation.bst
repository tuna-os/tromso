kind: cmake
description: qt6-qtlocation

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: >-
    -DINSTALL_ARCHDATADIR=lib
    -DQT_DISABLE_RPATH=ON

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtlocation-everywhere-src-6.10.3.tar.xz
  ref: 1d0abed99f2834a7c684d23c495c5f752611fee14726f286396cf7147376799e
