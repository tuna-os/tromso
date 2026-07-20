kind: cmake
description: polkit-qt-1

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/polkit.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DQT_MAJOR_VERSION=6

sources:
- kind: git_repo
  url: kde:libraries/polkit-qt-1.git
  track: master
  ref: 328a4c8615c7207e1297b776026657a77c6a71b6
