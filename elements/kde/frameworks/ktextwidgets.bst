kind: cmake
description: ktextwidgets

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcompletion.bst
- kde/qt6/qt6-qtspeech.bst
- kde/qt6/qt6-qtmultimedia.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/ktextwidgets.git
  track: master
  ref: v6.25.0-rc1-2-g0ad153af6cc675d04f6325093fc8a266247c10a3
