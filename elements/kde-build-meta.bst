kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/4d0855f.tar.gz
  ref: d3af7ac1640fc8aa138e7d4e125ee8faf54296f3e7e517ea84440cc4bb4d4efb
  base-dir: kde-build-meta-4d0855f87748c3ef8a41fc885b602c02510711e4

config:
  options:
    arch: "%{arch}"
