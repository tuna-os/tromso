kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/16d238b.tar.gz
  ref: 2882aba781b1a24d21f0c5175943933e916897866aae56a9cc6077b4450fa7ee
  base-dir: kde-build-meta-16d238be9eb46804bad4a67a8a74e32cff3d7a21

config:
  options:
    arch: "%{arch}"
