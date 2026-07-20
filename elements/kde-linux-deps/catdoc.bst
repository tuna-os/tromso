kind: autotools
description: Convert Word/Excel documents to text (catdoc)

sources:
- kind: tar
  url: tar_https:deb.debian.org/debian/pool/main/c/catdoc/catdoc_0.95.orig.tar.gz
  ref: 0d6ef66ff18d93915e62d77845194ba92bf49b60305c51f866a6f55421e37a79

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: >-
    --disable-wordview
  make-install-args: >-
    prefix="%{install-root}%{prefix}"
    bindir="%{install-root}%{bindir}"
    mandir="%{install-root}%{datadir}/man"
    sysconfdir="%{install-root}%{sysconfdir}"
    datadir="%{install-root}%{datadir}"
