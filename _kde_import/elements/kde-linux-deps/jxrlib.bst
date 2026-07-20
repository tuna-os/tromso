kind: manual
description: JPEG XR codec library

sources:
- kind: tar
  url: tar_https:github.com/mircomir/jxrlib/archive/refs/tags/1.3.2.tar.gz
  ref: 93d424d2fa697e88bbc4f74fa3db10491e77c83f4dcbdb3a8296a8d16242c16d

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/python3.bst

config:
  configure-commands:
  - sed -i 's/CFLAGS=-I\./CFLAGS=-I. -Wno-incompatible-pointer-types/' Makefile
  - sed -i 's/\bpython\b/python3/g' Makefile

  build-commands:
  - make SHARED=1 DIR_BUILD=./build

  install-commands:
  - make install SHARED=1 DIR_BUILD=./build DIR_INSTALL='%{install-root}%{prefix}'
  - |
    # Create symlinks for compat
    ldconfig -n '%{install-root}%{libdir}' 2>/dev/null || true
