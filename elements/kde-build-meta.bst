kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c42f0e2.tar.gz
  ref: c5aef8d1a2103ae6ea6428e1b21fee0fdcf9530979fb13390e0ee5acb6b4e650
  base-dir: kde-build-meta-c42f0e2a1480ca78941fbb44867b33ac4dd47410

config:
  options:
    arch: "%{arch}"
