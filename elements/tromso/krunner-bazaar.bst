kind: cmake
description: Aurora KRunner plugin for searching Flatpak apps via Bazaar

environment:
  LD_LIBRARY_PATH: /usr/lib

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/gettext.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/krunner.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF

sources:
- kind: git_repo
  url: github:bazaar-org/krunner-bazaar.git
  track: v[0-9]*
  ref: v1.3.0-0-gdbed96fa4c2e709c38432eb63e58289636f01b33
