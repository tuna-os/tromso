kind: cmake
description: qt6-qtnetworkauth

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtnetworkauth-everywhere-src-6.10.3.tar.xz
  ref: d88fe0cbce2b336bd34d81b3317732051115b874e9b958961b4b268ccccad594
