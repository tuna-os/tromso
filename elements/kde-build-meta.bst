kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8abead6.tar.gz
  ref: 1542ab1784e2ff83027cf0e0b6beb09506877d2c1ef80bd4970a882dec2b7ded
  base-dir: kde-build-meta-8abead6fa387e3f18f68b6ad67bbd0769f99ebbb

config:
  options:
    arch: "%{arch}"
