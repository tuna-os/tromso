kind: autotools
description: Intel power consumption and management analysis tool

sources:
- kind: git_repo
  url: github:fenrus75/powertop.git
  track: v2.15
  ref: d51ad395436d4d1dcc3ca46e1519ffeb475bf651

variables:
  autogen: |
    echo "2.15" > .tarball-version
    autoreconf -ivf

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libnl.bst
- freedesktop-sdk.bst:components/libcap.bst
- freedesktop-sdk.bst:components/pciutils.bst
- freedesktop-sdk.bst:components/systemd.bst
