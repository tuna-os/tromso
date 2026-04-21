kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0f5ae76.tar.gz
  ref: 7fa4fcdc528ce61a2ca86ba03592fe2a73e8aa8fc2f94545ba36ea9b9162f4e3
  base-dir: kde-build-meta-0f5ae7698e1b12d486e252e05d84e7a469478249

config:
  options:
    arch: "%{arch}"
