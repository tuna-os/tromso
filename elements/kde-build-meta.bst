kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/cb92834.tar.gz
  ref: 56d9279723c44920d54b882d3fefb5d64a45ccb64fcc031c9ef9e1ac7755cccf
  base-dir: kde-build-meta-cb92834cdc412c7835e648fee12fde8049697f6f

config:
  options:
    arch: "%{arch}"
