kind: cmake
description: qt6-qtserialport

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qtserialport-everywhere-src-6.10.3.tar.xz
  ref: 3fb30bec133316b6f65b6e03a38087a59c7d337cd9b021486a814a9bc10a31ef
