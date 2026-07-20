kind: autotools
description: Filesystem in Userspace (FUSE) 2.x - required by cryfs

sources:
- kind: tar
  url: tar_https:github.com/libfuse/libfuse/releases/download/fuse-2.9.9/fuse-2.9.9.tar.gz
  ref: d0e69d5d608cc22ff4843791ad097f554dd32540ddc9bed7638cc6fea7c1b4b5

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gettext.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: >-
    --disable-example
    --disable-static
    --enable-lib
    --disable-util
