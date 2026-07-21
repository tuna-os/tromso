kind: cmake
description: qt6-qtcharts

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtcharts-everywhere-src-6.10.3.tar.xz
  ref: ab64abd0ff99f90cf290041f5e4283a702f6c2434d30eb460fd3765081e86f15
