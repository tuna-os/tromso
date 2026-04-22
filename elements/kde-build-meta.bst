kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/3214eda.tar.gz
  ref: f910ebb6db0297a92395db4a0aafaf713f4e6a8346dc785ee73590cd3d45e830
  base-dir: kde-build-meta-3214eda7cbc16573385704c920a245f0b5d1a2d4

config:
  options:
    arch: "%{arch}"
