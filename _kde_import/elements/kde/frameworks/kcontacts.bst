kind: cmake
description: kcontacts

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcodecs.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kcontacts.git
  track: master
  ref: v6.25.0-rc1-5-g4a5ddf76b0e9847226d7c6f92932ed2cea975bfd
