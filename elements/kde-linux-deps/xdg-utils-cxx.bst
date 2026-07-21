kind: cmake
description: Freedesktop standards C++ implementation (needed by libappimage)

sources:
- kind: tar
  url: tar_https:github.com/azubieta/xdg-utils-cxx/archive/refs/tags/v1.0.1.tar.gz
  ref: 2cdeda2385faa0ce496a5b276f5145f2dfb3f67ee77789cf8f57752abc83e69b

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DXDG_UTILS_TESTS=OFF
    -DXDG_UTILS_SHARED=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
