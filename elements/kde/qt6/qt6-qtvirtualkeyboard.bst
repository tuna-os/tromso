kind: cmake
description: Qt6 virtual keyboard module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/hunspell.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/qt6/qt6-qtsvg.bst

depends:
- freedesktop-sdk.bst:components/hunspell.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/qt6/qt6-qtsvg.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtvirtualkeyboard-everywhere-src-6.10.3.tar.xz
  ref: 3298e26dfa4fad2363e3dfb2b55079c54fc8115a4a040d9616e5619f095d8fb5
