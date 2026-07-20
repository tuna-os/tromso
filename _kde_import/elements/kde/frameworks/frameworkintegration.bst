kind: cmake
description: frameworkintegration

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/attica.bst
- kde/frameworks/karchive.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/frameworkintegration.git
  track: master
  ref: v6.25.0-rc1-3-g9cf631d1acdf772e2502c9506454fdb129e444b3
