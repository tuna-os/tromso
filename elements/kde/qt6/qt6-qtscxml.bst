kind: cmake
description: qt6-qtscxml

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtscxml-everywhere-src-6.10.3.tar.xz
  ref: 26d3e6ae104a762b4c957bf45a382efb1caec2e16333f8dfa88158a8f2620809
