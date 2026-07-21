kind: cmake
description: libqaccessibilityclient

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF

sources:
- kind: git_repo
  url: kde:libraries/libqaccessibilityclient.git
  track: master
  ref: 783ff72b58aceeb788d0ac2a86f5f6da5a8310e7
