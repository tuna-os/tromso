kind: autotools

sources:
- kind: git_repo
  url: github:ckolivas/lrzip
  track: v*
  ref: v0.660-0-gb9e8784d8d6806e733d0b4207731bf895d1c14db

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:components/lzo.bst
- freedesktop-sdk.bst:components/bzip2.bst
- freedesktop-sdk.bst:components/lz4.bst
- freedesktop-sdk.bst:components/xz.bst

variables:
  conf-local: --disable-static
