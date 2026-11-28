kind: cmake
description: kimageformats

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/karchive.bst
- freedesktop-sdk.bst:components/libjxl.bst

depends:
- freedesktop-sdk.bst:components/libjxl.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kimageformats.git
  track: master
  ref: v6.32.0-rc1-14-gaf56f040d069c1cdd4e39355816fb041eaf67c40
