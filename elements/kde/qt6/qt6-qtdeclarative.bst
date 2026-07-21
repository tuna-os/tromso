kind: cmake
description: Qt6 declarative (QML) module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- kde/qt6/qt6-qtshadertools.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtdeclarative-everywhere-src-6.10.3.tar.xz
  ref: dadf80d43b8e08ca63aa65d46859a42b920a7777cf7e0ecfcb4c4537f9e65c76
