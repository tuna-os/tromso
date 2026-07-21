kind: cmake
description: kdeclarative

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kio.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kglobalaccel.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcolorscheme.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kdeclarative.git
  track: master
  ref: v6.25.0-rc1-4-g110100133034f568c5d14041dff867df556a3a92
