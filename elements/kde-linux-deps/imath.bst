kind: cmake
description: Imath - math library for VFX and animation

sources:
- kind: tar
  url: tar_https:github.com/AcademySoftwareFoundation/Imath/archive/v3.2.2.tar.gz
  ref: b4275d83fb95521510e389b8d13af10298ed5bed1c8e13efd961d91b1105e462

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- freedesktop-sdk.bst:components/zlib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DPYTHON=OFF
