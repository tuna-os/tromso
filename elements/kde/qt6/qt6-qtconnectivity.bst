kind: cmake
description: Qt6 connectivity module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtconnectivity-everywhere-src-6.10.3.tar.xz
  ref: 6f675f3165ca3d06ee7a7bd234e2d58fe72f02e68c1e9c4ccb21fe8b1a93d478
