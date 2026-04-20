kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c351a02.tar.gz
  ref: a3ffdd8dacf78277e66b62a9101d7aaa91ad0ee9206b2bc6115c95fcccd4701c
  base-dir: kde-build-meta-c351a02fe347c5b3f3661daf4f2997e15340e8f9

config:
  options:
    arch: "%{arch}"
