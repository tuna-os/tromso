kind: cmake
description: qt6-qthttpserver

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qthttpserver-everywhere-src-6.10.3.tar.xz
  ref: cdc9ad1a5b7a3de58a46c065b015f88d4f8ebe7052a346a9aa5465e510ff0deb
