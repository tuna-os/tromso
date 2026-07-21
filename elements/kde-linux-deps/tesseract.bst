kind: cmake
description: Tesseract OCR engine

sources:
- kind: tar
  url: tar_https:github.com/tesseract-ocr/tesseract/archive/5.5.2/tesseract-5.5.2.tar.gz
  ref: 6235ea0dae45ea137f59c09320406f5888383741924d98855bd2ce0d16b54f21

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- kde-linux-deps/leptonica.bst
- kde-linux-deps/tesseract-data-eng.bst
- freedesktop-sdk.bst:components/libarchive.bst
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_TRAINING_TOOLS=OFF
    -DUSE_SYSTEM_ICU=OFF
    -DBUILD_TESTS=OFF
    -DENABLE_LTO=OFF
