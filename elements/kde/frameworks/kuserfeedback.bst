kind: cmake
description: kuserfeedback

build-depends:
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kcoreaddons.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtcharts.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qttools.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF

sources:
- kind: git_repo
  url: kde:frameworks/kuserfeedback.git
  track: master
  ref: v6.32.0-rc1-5-g9ac7b755f2ba590e6a90e34e390911bfdb652776
