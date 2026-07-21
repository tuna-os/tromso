kind: cmake
description: OpenEXR HDR image format library

sources:
- kind: tar
  url: tar_https:github.com/AcademySoftwareFoundation/openexr/archive/v3.4.11.tar.gz
  ref: 63730442f5fd6c5a79395bdd199040ab3821c229066049f52a57424a984b16ed

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- kde-linux-deps/imath.bst
- freedesktop-sdk.bst:components/zlib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DOPENEXR_BUILD_PYTHON=OFF
    -DOPENEXR_FORCE_INTERNAL_DEFLATE=ON
    -DOPENEXR_INSTALL_EXAMPLES=OFF
