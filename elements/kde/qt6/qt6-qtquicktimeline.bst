kind: cmake
description: qt6-qtquicktimeline

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtquicktimeline-everywhere-src-6.10.3.tar.xz
  ref: ca3d32afdbfd01860e0d5ca3010e9d6928ca3d545077edb8f8ce8148f16f62ae
