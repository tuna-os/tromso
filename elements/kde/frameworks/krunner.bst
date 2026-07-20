kind: cmake
description: krunner

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kio.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/kitemmodels.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON

sources:
- kind: git_repo
  url: kde:frameworks/krunner.git
  track: master
  ref: v6.25.0-rc1-2-g4bf69681d9b459f9a1a0c0548cc01ba6e96c802a
