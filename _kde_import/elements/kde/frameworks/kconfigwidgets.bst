kind: cmake
description: kconfigwidgets

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kconfigwidgets.git
  track: master
  ref: v6.25.0-rc1-4-g5f7c21ffa34d6027448a7e62697eb011c2b0c125
