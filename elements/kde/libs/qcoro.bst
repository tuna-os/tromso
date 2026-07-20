kind: cmake
description: qcoro - C++ coroutines for Qt

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtwebsockets.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DQCORO_BUILD_EXAMPLES=OFF

sources:
- kind: git_repo
  url: github:danvratil/qcoro.git
  track: main
  ref: 720ea7f6322bbba9f5d5aa3888a222397a1f72f1
