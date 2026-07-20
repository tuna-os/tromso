kind: cmake
description: Fast neofetch-like system information tool

sources:
- kind: tar
  url: github:fastfetch-cli/fastfetch/archive/refs/tags/2.62.1.tar.gz
  ref: 8c4833e55b8b445a32c7cb7570007b5e10a9ee4cee74a494004ba61e88b12b26

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/vulkan-icd-loader.bst

variables:
  cmake-local: >-
    -DBUILD_TESTS=OFF
    -DENABLE_RPM=OFF
    -DENABLE_IMAGEMAGICK7=OFF
    -DENABLE_IMAGEMAGICK6=OFF
    -DENABLE_CHAFA=OFF
