kind: autotools
description: Library for serialization of property lists (libimobiledevice dependency)

sources:
- kind: git_repo
  url: github:libimobiledevice/libplist.git
  track: "2.2.0"
  ref: 2.2.0-0-gc5a30e9267068436a75b5d00fcbf95cb9c1f4dcd

variables:
  autogen: |
    echo "2.2.0" > .tarball-version
    autoreconf -ivf
  conf-local: >-
    --without-cython

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
