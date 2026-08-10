kind: cmake
description: kcoreaddons

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-shiboken6.bst
- kde/qt6/qt6-pyside6.bst

depends:
- freedesktop-sdk.bst:components/util-linux.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kcoreaddons.git
  track: master
  ref: v6.25.0-rc1-21-gebb91dae25ecb10199878945bcd4d88658b6dd46
