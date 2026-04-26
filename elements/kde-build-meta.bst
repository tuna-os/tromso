kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/ebc41e5d6.tar.gz
  ref: 2b7d9f7dd6bd3879cef7fdb1daf07cdfb2f5eaf4551883543457e573183c1af0
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
