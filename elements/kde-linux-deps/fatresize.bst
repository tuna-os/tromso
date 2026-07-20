kind: autotools
description: FAT filesystem resize tool

sources:
- kind: git_repo
  url: github:ya-mouse/fatresize.git
  track: v1.1.0
  ref: 316981e43b14f42a9aa7b461c97e1f61f6f2390b

variables:
  autogen: |
    echo "1.1.0" > .tarball-version
    autoreconf -ivf
  conf-local: --disable-static

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/parted.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/parted.bst

config:
  build-commands:
  - find . -name Makefile | xargs -r sed -i 's/-D_FILE_OFFSET_BITS=[[:blank:]]/-D_FILE_OFFSET_BITS=64 /g; s/-D_FILE_OFFSET_BITS=$/-D_FILE_OFFSET_BITS=64/g' || true
  - make %{make-args}
