kind: cmake
description: Intel VPL GPU Runtime (oneVPL-intel-gpu) - hardware accelerated video decode/encode

sources:
- kind: tar
  url: github_files:intel/vpl-gpu-rt/archive/intel-onevpl-26.1.5/vpl-gpu-rt-26.1.5.tar.gz
  ref: d2f297dc03d4e5585bee75ce3bafc5c8a35b30ac60ff7d6b49c1ed6f6b8152a3

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde-linux-deps/libvpl.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libva.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-linux-deps/libvpl.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libva.bst

variables:
  cmake-local: >-
    -DBUILD_TESTS=OFF
    -DMFX_ENABLE_AENC=ON
