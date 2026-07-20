kind: make
description: Open source L2TP implementation used by NetworkManager-l2tp

sources:
- kind: tar
  url: github_files:xelerance/xl2tpd/archive/v1.3.20.tar.gz
  ref: 3db95450c5e1efaeea7547af344b5621f4453af3c227f26ec43bcbc79087b045

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- core-deps/ppp.bst
- freedesktop-sdk.bst:components/openssl.bst

variables:
  make-args: >-
    PREFIX=%{prefix}
    SBINDIR=%{sbindir}
    MANDIR=%{mandir}

config:
  # xl2tpd Makefile does not support DESTDIR; pass all install paths with install-root prefix
  install-commands:
  - |
    make -j1 \
      PREFIX="%{install-root}%{prefix}" \
      SBINDIR="%{install-root}%{sbindir}" \
      BINDIR="%{install-root}%{bindir}" \
      MANDIR="%{install-root}%{mandir}" \
      install
