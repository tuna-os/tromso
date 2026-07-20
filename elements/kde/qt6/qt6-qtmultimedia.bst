kind: cmake
description: Qt6 multimedia module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtquick3d.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- kde/qt6/qt6-qtshadertools.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtmultimedia-everywhere-src-6.10.3.tar.xz
  ref: dd228fe54051e8834ca53e558794742c8814f217849f9dfa8f9a9df80441903a
