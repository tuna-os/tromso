kind: cmake
description: Intel Video Processing Library (libvpl)

sources:
- kind: tar
  url: github_files:intel/libvpl/archive/v2.16.0/libvpl-2.16.0.tar.gz
  ref: d60931937426130ddad9f1975c010543f0da99e67edb1c6070656b7947f633b6

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTS=OFF
    -DINSTALL_EXAMPLES=OFF
