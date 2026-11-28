kind: cmake
description: KCGroups with the dmem cgroup controller (library of the booster)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde/qt6/qt6-qtbase.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_WITH_QT6=ON

sources:
# Tag kcgroups-dmemcg-experimental-0.2
- kind: git_repo
  url: github:pixelcluster/kcgroups.git
  ref: d106f1c8f44c1f231a9050b2bf82a34bb7d5db32
