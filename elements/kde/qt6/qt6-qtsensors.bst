kind: cmake
description: qt6-qtsensors

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtsensors-everywhere-src-6.10.3.tar.xz
  ref: c821ca985040f2326923d1ca05f2e91f7a45a1bf8bb8c072b712dfe1f7cb8d6e
