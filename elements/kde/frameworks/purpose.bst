kind: cmake
description: purpose

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kio.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/knotifications.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/prison.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kcmutils.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/purpose.git
  track: master
  ref: v6.25.0-rc1-18-g92e044388f0c246bcc7ad061f4dd5d32ca5783e6
