kind: cmake
description: networkmanager-qt

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- sdk/glib.bst

depends:
- core-deps/NetworkManager.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DWITH_NMQT_STATIC=OFF

sources:
- kind: git_repo
  url: kde:frameworks/networkmanager-qt.git
  track: master
  ref: v6.25.0-rc1-1-g0d82c49f01cf34cd4c654b2f56139fcf1db2cd92
