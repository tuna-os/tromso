kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c351a02.tar.gz
  ref: a3ffdd8dacf78277e66b62a9101d7aaa91ad0ee9206b2bc6115c95fcccd4701c
  base-dir: kde-build-meta-c351a0233e940c471c73f0e1981e675830882510

config:
  options:
    arch: "%{arch}"
