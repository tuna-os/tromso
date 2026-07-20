kind: meson
sources:
- kind: tar
  url: videolan_pub:videolan/libdvdread/7.0.1/libdvdread-7.0.1.tar.xz
  ref: 2e3e04a305c15c3963aa03ae1b9a83c1d239880003fcf3dde986d3943355d407

build-depends:
- freedesktop-sdk.bst:components/doxygen.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- core-deps/libdvdcss.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  meson-local: >-
    -Denable_docs=true
