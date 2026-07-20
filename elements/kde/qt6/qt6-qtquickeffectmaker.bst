kind: cmake
description: qt6-qtquickeffectmaker

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtquickeffectmaker-everywhere-src-6.10.3.tar.xz
  ref: 5cb68c1195d344f01bca031bbb826b18b66e13bcd8abd97cfa5f059f0cd1a4f6
