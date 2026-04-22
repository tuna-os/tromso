kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/fab7e4d.tar.gz
  ref: a22b7cfedda8170ac57ae15cf8eda78d7a8179c5bda9d327fb88d39c178e0a10
  base-dir: kde-build-meta-fab7e4db37b09ce7c391d902a65d6ce82cab1274

config:
  options:
    arch: "%{arch}"
