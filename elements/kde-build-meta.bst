kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/5a7db94.tar.gz
  ref: b537d431245624c27b005de19fd3739606199a9d166851a5b777a2d39dab7f28
  base-dir: kde-build-meta-5a7db947a6551271dc8ac6157153790f2ad297c1

config:
  options:
    arch: "%{arch}"
