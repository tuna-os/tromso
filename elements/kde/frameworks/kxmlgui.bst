kind: cmake
description: kxmlgui

depends:
- kde/frameworks/kiconthemes.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcolorscheme.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kxmlgui.git
  track: master
  ref: v6.25.0-rc1-10-g84408ae9dc72e003ead66c2fd03907aecdf94c34
