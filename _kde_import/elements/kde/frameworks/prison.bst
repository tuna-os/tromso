kind: cmake
description: prison

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-qtmultimedia.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/libs/qrencode.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DWITH_DMTX=OFF -DWITH_ZXING=OFF

sources:
- kind: git_repo
  url: kde:frameworks/prison.git
  track: master
  ref: v6.25.0-rc1-1-gc9074e68ec869ff098cf898794983662cdba2637
