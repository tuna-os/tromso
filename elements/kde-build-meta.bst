kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/ea0b79ef.tar.gz
  ref: db3e0ae078a92cf2fb21704e02fd47ba3d10804dbc95279c6832be288dd4be13
  base-dir: kde-build-meta-ea0b79ef7a0385c46761a00bb506d065e1a7de00

config:
  options:
    arch: "%{arch}"
