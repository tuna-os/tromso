kind: cmake
description: kparts

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kio.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kauth.bst
- kde/frameworks/solid.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/karchive.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kparts.git
  track: master
  ref: v6.25.0-rc1-4-g8d02a58d54c0bfb403a59fcc920b0338343bc64a
