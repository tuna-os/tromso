kind: cmake
description: qt6-webchannel

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtwebchannel-everywhere-src-6.10.3.tar.xz
  ref: 9797953a17220b24f531ef09d3f49aa69add369aa6c32b5b2e07f2916a8129b5
