kind: manual
description: LMDB - Lightning Memory-Mapped Database

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

config:
  build-commands:
  - make -C libraries/liblmdb
  install-commands:
  - make -C libraries/liblmdb install prefix="%{prefix}" DESTDIR="%{install-root}"
    INCLUDEDIR="%{prefix}/include" LIBDIR="%{prefix}/%{libdir}"

variables:
  prefix: /usr
  libdir: lib/x86_64-linux-gnu

sources:
- kind: tar
  url: github:LMDB/lmdb/archive/LMDB_0.9.35.tar.gz
  ref: 18b021fd589d30cc08860a9550a30ae51637117451385e9581616da751326632
  base-dir: lmdb-LMDB_0.9.35
