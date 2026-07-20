kind: cmake
description: qt6-qtpositioning

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtpositioning-everywhere-src-6.10.3.tar.xz
  ref: 64cf6c5d1137378ec6a276d3f6e5be7b9d299436d66cea36ebd31035314287a2
