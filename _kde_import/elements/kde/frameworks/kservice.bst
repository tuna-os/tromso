kind: cmake
description: kservice

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdoctools.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON

sources:
- kind: git_repo
  url: kde:frameworks/kservice.git
  track: master
  ref: v6.25.0-rc1-2-g4b53e07213d155d0502b794e5f90ad512338b3bc
