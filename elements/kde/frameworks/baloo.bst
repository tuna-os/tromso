kind: cmake
description: baloo

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/frameworks/kio.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/solid.bst
- kde/frameworks/kfilemetadata.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdoctools.bst
- kde/libs/lmdb.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/karchive.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/util-linux.bst

depends:
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/frameworks/kio.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON

sources:
- kind: git_repo
  url: kde:frameworks/baloo.git
  track: master
  ref: v6.25.0-rc1-12-ge177085e31226013ac3aefee5851b81e3c152f18
