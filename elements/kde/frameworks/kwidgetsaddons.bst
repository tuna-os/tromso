kind: cmake
description: kwidgetsaddons

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
# PySide6 is omitted from the image graph until shiboken 6.10.3's nested-enum
# wrapper bug against Qt 6.10.3 is fixed. BUILD_PYTHON_BINDINGS=OFF, so the
# bindings are not needed here. Re-add qt6-pyside6.bst when fixed; see
# docs/UPSTREAM-ALIGNMENT.md.

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kwidgetsaddons.git
  track: master
  ref: v6.25.0-rc1-13-gbc9886598671b9bc964b6815b2e869d1d2ddc1e9
