kind: cmake
description: Range library for C++11/14/17

sources:
- kind: tar
  url: github_files:ericniebler/range-v3/archive/refs/tags/0.12.0.tar.gz
  ref: 015adb2300a98edfceaf0725beec3337f542af4915cec4d0b89fa0886f4ba9cb

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DRANGE_V3_TESTS=OFF
    -DRANGE_V3_EXAMPLES=OFF
    -DRANGE_V3_DOCS=OFF
