kind: cmake
description: qt6-qt3d

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qt3d-everywhere-src-6.10.3.tar.xz
  ref: f53e47187be2487d8a23ef6fe5ed72f7c3c5fab706de3b61e165b0124c09ecd7
