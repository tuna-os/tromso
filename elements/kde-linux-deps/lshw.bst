kind: make
description: Hardware lister - detailed information about hardware configuration

sources:
- kind: tar
  url: github:lyonel/lshw/archive/ad4f7aaa1d55baf580908d9be36422df5c333d79.tar.gz
  ref: a18c28424ebab15276e3de06030f7cd8cfe14d2114527b42811155152967556f

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/pkg-config.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  make-args: PREFIX="%{prefix}" DESTDIR=""
  make-install-args: PREFIX="%{prefix}" DESTDIR="%{install-root}"
