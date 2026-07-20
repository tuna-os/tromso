kind: cmake
description: qrencode - QR Code generation library

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

variables:
  cmake-local: >-
    -DBUILD_SHARED_LIBS=ON
    -DWITH_TOOLS=OFF
    -DWITH_TEST=OFF
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5

sources:
- kind: tar
  url: github_files:fukuchi/libqrencode/archive/v4.1.1.tar.gz
  ref: 5385bc1b8c2f20f3b91d258bf8ccc8cf62023935df2d2676b5b67049f31a049c
