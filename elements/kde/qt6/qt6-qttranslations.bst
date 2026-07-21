kind: cmake
description: qt6-qttranslations

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qttranslations-everywhere-src-6.10.3.tar.xz
  ref: 52689984b114d4d34516d5d7bfb0c75857b1c3ff529921042144f09ab2de3a83
