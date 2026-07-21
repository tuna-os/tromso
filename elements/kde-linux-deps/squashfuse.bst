kind: autotools
description: FUSE-based filesystem for SquashFS (required by libappimage)

sources:
- kind: tar
  url: tar_https:github.com/vasi/squashfuse/archive/refs/tags/0.6.1.tar.gz
  ref: 7730066d1e9baf0084c71674d168331296921e0d7ae0f34de7307744be4ed568

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/fuse3.bst

depends:
- freedesktop-sdk.bst:components/fuse3.bst
- freedesktop-sdk.bst:components/zlib.bst
- freedesktop-sdk.bst:components/xz.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

# fuse3.bst installs fuse3.pc to arch-specific pkgconfig dir not on default search path
environment:
  PKG_CONFIG_PATH: /usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig

variables:
  conf-local: --disable-static
