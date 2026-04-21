kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f5a7ef4.tar.gz
  ref: 9fdf01c80fc4081b308177f997abb9ac4226886b09d64bcfdbbe65cd78740bf2
  base-dir: kde-build-meta-f5a7ef4b14cc37d3df4a50df546b2f9575075cc2

config:
  options:
    arch: "%{arch}"
