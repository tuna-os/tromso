kind: cmake
description: breeze-icons

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DWITH_ICON_GENERATION=OFF

sources:
- kind: git_repo
  url: kde:frameworks/breeze-icons.git
  track: master
  ref: v6.25.0-rc1-2-g2b44e6da1e90162ae971e6f3acd8de5958309685
