kind: cmake
description: qt6-qtquick3d

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtquick3d-everywhere-src-6.10.3.tar.xz
  ref: 7e7b0e66ad0f786595ff250301be5d4dd9ba35c6d96e331d7b8ddf1bcbb250b7
