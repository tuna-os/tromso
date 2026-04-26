kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/04841f73f.tar.gz
  ref: 222d8898fd16f730dbeb812d7af5f285312599fb6601cb86e3a722d25765b46b
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
