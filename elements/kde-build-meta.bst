kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/194586e.tar.gz
  ref: 61ad8efae2d276d26b60aed0f7cbda7f4f3b52ae56a83ae42d3bc45d4810f3d3
  base-dir: kde-build-meta-194586ef255fb59afb6337e20667806844fac19e

config:
  options:
    arch: "%{arch}"
