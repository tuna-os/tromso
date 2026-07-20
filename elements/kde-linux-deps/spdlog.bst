kind: cmake
description: Fast C++ logging library (header-only mode)

sources:
- kind: tar
  url: github_files:gabime/spdlog/archive/refs/tags/v1.15.3.tar.gz
  ref: 15a04e69c222eb6c01094b5c7ff8a249b36bb22788d72519646fb85feb267e67

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DSPDLOG_BUILD_EXAMPLES=OFF
    -DSPDLOG_BUILD_TESTS=OFF
    -DSPDLOG_BUILD_BENCH=OFF
    -DSPDLOG_FMT_EXTERNAL=OFF
