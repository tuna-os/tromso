kind: cmake
description: ktexteditor

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-qtspeech.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/kparts.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/syntax-highlighting.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kio.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/knotifications.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/ktexteditor.git
  track: master
  ref: v6.25.0-rc1-20-g48ec7c3bc683c90e55d8aa27332dc3930dd1f9a4
