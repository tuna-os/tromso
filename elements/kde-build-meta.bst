kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9611560.tar.gz
  ref: e48a53cb11653d3d913d3eba2fca4bd28ac93bd7f51cbd2e7148a9bf743436f0
  base-dir: kde-build-meta-9611560b6d320d3818d8cce770cee10327c9d6e7

config:
  options:
    arch: "%{arch}"
