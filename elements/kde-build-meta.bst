kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c02274f.tar.gz
  ref: d1746b0411bb8e1dbed98cc18fd5d596f28ef5b732e9d7e63621f9d39077366d
  base-dir: kde-build-meta-c02274f1476219a72eca0676191be3c2447d9b9f

config:
  options:
    arch: "%{arch}"
