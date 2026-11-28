kind: cmake
description: kirigami

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-qtsvg.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kirigami.git
  track: master
  ref: v6.32.0-rc1-50-g39c48e6274de031a9d3adacaf69cd3efa2acc360
