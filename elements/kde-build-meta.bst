kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c636bfe.tar.gz
  ref: 7c8dabaaa489ce1e123dff0a1e787f1a3ec5bd44450d15aec30f3d56d932ea23
  base-dir: kde-build-meta-c636bfe585865eeed739019e2d90900c3f8f91cf

config:
  options:
    arch: "%{arch}"
