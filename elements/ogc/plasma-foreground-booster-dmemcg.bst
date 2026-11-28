kind: cmake
description: >-
  Tells the dmem cgroup controller which Plasma window is in the foreground

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kwindowsystem.bst
- kde/plasma/plasma-workspace.bst
- ogc/kcgroups-dmemcg.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kwindowsystem.bst
- kde/plasma/plasma-workspace.bst
- ogc/kcgroups-dmemcg.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_WITH_QT6=ON
    -DCMAKE_SKIP_INSTALL_RPATH=ON

sources:
# Tag booster-dmemcg-experimental-0.2
- kind: git_repo
  url: github:pixelcluster/kcgroups.git
  ref: 295961729f8eccbbbd2b81af12f04291318225fa
