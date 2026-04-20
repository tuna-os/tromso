kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/d908dda.tar.gz
  ref: 670b878db311d20a2a28c1f3c8cccc59dbd2817c0052dc583d2cf93a2fff86e5
  base-dir: kde-build-meta-d908ddafa0147fa291b7cd73430c4f075fc82de1

config:
  options:
    arch: "%{arch}"
