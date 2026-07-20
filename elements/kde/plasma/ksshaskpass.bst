kind: cmake
description: ksshaskpass - SSH password dialog for KDE

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/glib.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kdoctools.bst
- kde/libs/qtkeychain-qt6.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kwidgetsaddons.bst

variables:
  cmake-local: >-
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/ksshaskpass.git
  track: master
  ref: v6.5.90-21-g990f0f2fbd1919ec2576b035c007e5cc69f25aaf
