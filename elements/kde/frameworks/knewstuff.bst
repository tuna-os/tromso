kind: cmake
description: knewstuff

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/kio.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kbookmarks.bst
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
- kde/frameworks/kguiaddons.bst

depends:
- kde/frameworks/attica.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/knewstuff.git
  track: master
  ref: v6.25.0-rc1-3-gc8244e0b4d3b51cac8c4b0fcdd20cf8e9e258d40
