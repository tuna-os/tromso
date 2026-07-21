kind: cmake
description: kcmutils

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kio.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/solid.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kirigami.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kcmutils.git
  track: master
  ref: v6.25.0-rc1-11-gec1fc33312728581580ff3bd36bff61e55b3da3c
