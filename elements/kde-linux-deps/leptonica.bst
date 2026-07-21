kind: cmake
description: Leptonica - image processing and analysis library (required by Tesseract)

sources:
- kind: tar
  url: tar_https:github.com/DanBloomberg/leptonica/archive/refs/tags/1.85.0.tar.gz
  ref: c01376bce0379d4ea4bc2ec5d5cbddaa49e2f06f88242619ab8c059e21adf233

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:components/jpeg.bst
- freedesktop-sdk.bst:components/libpng.bst
- freedesktop-sdk.bst:components/zlib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_PROG=OFF
    -DENABLE_GIF=OFF
    -DENABLE_OPENJPEG=OFF
    -DENABLE_WEBP=OFF
    -DENABLE_TIFF=OFF
