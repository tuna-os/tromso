kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/095688e2d.tar.gz
  ref: c015890203a3d4eac0420df5264ae26aa854a37648d79a625de84c010d80ffc1
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
