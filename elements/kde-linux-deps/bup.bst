kind: make
description: Git-based backup tool

sources:
- kind: git_repo
  url: github:bup/bup.git
  track: 0.33.10
  ref: 0fd0f5a8e928c9c93900f9d6f54fec61c855614a

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-setuptools.bst
- freedesktop-sdk.bst:components/perl.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/git.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/openssl.bst

variables:
  make-args: PYTHON=python3
  make-install-args: >-
    PYTHON=python3
    DESTDIR="%{install-root}"
    MANDIR="%{datadir}/man"
    BINDIR="%{bindir}"
    LIBDIR="%{libdir}/bup"
