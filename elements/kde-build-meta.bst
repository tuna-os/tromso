kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c6d1410.tar.gz
  ref: 60fe29486ab4b4b24b766e57b19cb742800813832f347e0918d14adab4eecb30
  base-dir: kde-build-meta-c6d141084cef99e3b608dd9f23cbdfff506b09a7

config:
  options:
    arch: "%{arch}"
