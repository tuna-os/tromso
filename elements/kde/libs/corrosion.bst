kind: cmake
description: corrosion - integrate Rust into CMake projects

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/rust.bst

variables:
  cmake-local: >-
    -DCORROSION_BUILD_TESTS=OFF

sources:
- kind: git_repo
  url: github:corrosion-rs/corrosion.git
  track: 'v*'
  ref: v0.6.1-0-g1499b14e4906a2890f5cee1547c8848db261753d
