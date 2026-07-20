kind: cmake
description: kio-admin - KIO worker for admin file operations

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kio.bst
- kde/frameworks/ki18n.bst
- kde/libs/polkit-qt-1.bst
- freedesktop-sdk.bst:components/polkit.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DQT_MAJOR_VERSION=6

sources:
- kind: git_repo
  url: kde:system/kio-admin.git
  track: master
  ref: v24.01.90-128-g1f674047fb58e9280f2f6bebda1cd46933ff4910
