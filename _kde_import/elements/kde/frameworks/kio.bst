kind: cmake
description: kio

depends:
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/kded.bst
- kde/frameworks/kwallet.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/util-linux.bst
- freedesktop-sdk.bst:components/systemd-libs.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DWITH_X11=ON -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON

sources:
- kind: git_repo
  url: kde:frameworks/kio.git
  track: master
  ref: v6.25.0-rc1-45-gbc1189a3aef92bbabfeef27f4cacbb6802e92aa3
