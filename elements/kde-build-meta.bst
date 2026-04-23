kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f4660a6.tar.gz
  ref: 68d5b57a85eed6544209671fe9b4bcf77806581590814f730db36259464c13e8
  base-dir: kde-build-meta-f4660a6c42bf9d8008dd347e4ff3d535c3c1ed11

config:
  options:
    arch: "%{arch}"
