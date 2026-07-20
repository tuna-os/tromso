kind: cmake
description: Qt6 Wayland module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtwayland-everywhere-src-6.10.3.tar.xz
  ref: 2e93322a86b562113cfa3a5f0aa8b1e4e185d6284af49b529578d27d52ca85d3
