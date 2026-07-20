kind: autotools
description: inotifywait and inotifywatch CLI tools for filesystem event monitoring

sources:
- kind: git_repo
  url: github:inotify-tools/inotify-tools.git
  track: "4.25.9.0"
  ref: 81c6c9881edf4844f2b8250e63f82da9cb7f5444

variables:
  autogen: |
    echo "4.25.9.0" > .tarball-version
    autoreconf -ivf

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
