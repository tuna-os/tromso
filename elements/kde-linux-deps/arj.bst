kind: autotools
description: ARJ archive format tool

sources:
- kind: tar
  url: tar_https:deb.debian.org/debian/pool/main/a/arj/arj_3.10.22.orig.tar.gz
  ref: 589e4c9bccc8669e7b6d8d6fcd64e01f6a2c21fe10aad56a83304ecc3b96a7db

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
