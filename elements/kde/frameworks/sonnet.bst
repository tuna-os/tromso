kind: cmake
description: sonnet

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/hunspell.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DSONNET_USE_ASPELL=OFF
    -DSONNET_USE_HSPELL=OFF
    -DSONNET_USE_VOIKKO=OFF

sources:
- kind: git_repo
  url: kde:frameworks/sonnet.git
  track: master
  ref: v6.25.0-rc1-4-g49c0709c76aac3108172c935cd0c7db325687f5c
