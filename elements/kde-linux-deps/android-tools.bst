kind: cmake
description: ADB and fastboot Android platform tools (nmeum community fork) v37.0.0p1

sources:
- kind: tar
  url: github_files:nmeum/android-tools/releases/download/37.0.0p1/android-tools-37.0.0p1.tar.xz
  ref: 2c6de1abe16b211c7d9f59276217e14fd9e0e18b20e331d3c84358f5dffd576e

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/perl.bst
- freedesktop-sdk.bst:components/go.bst
- freedesktop-sdk.bst:components/sed.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/zstd.bst
- freedesktop-sdk.bst:components/brotli.bst
- freedesktop-sdk.bst:bootstrap/pcre2.bst
- freedesktop-sdk.bst:components/protobuf.bst
- freedesktop-sdk.bst:components/lz4.bst
- freedesktop-sdk.bst:components/e2fsprogs.bst

config:
  configure-commands:
  - |
    # Create minimal gtest stub: zip_writer.h includes gtest_prod.h for FRIEND_TEST even in non-test builds
    mkdir -p gtest-stub/gtest
    printf '#pragma once\n#define FRIEND_TEST(tc, tn) friend class tc##_##tn##_Test\n' \
      > gtest-stub/gtest/gtest_prod.h
  - cmake -B%{build-dir} -H"%{conf-root}" -G"%{generator}" %{cmake-args} -DCMAKE_CXX_FLAGS="-I$(pwd)/gtest-stub"

variables:
  cmake-local: >-
    -DANDROID_TOOLS_PATCH_VENDOR=ON
    -DANDROID_TOOLS_USE_BUNDLED_FMT=ON
    -DANDROID_TOOLS_USE_BUNDLED_LIBUSB=OFF
