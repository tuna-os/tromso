kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/bc30ce0c4.tar.gz
  ref: 794fdb5fd3a1a338e654163405ba5a400fc90a06dd08dadc1affd3a0b3c935ee
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
