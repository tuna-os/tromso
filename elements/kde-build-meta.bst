kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/fa20187.tar.gz
  ref: 35a8c15a0f345dbceccacb423c719b548017c334e022e44733debbd27c5832e1
  base-dir: kde-build-meta-fa201870785d96dbc6a39f5509512107638d6946

config:
  options:
    arch: "%{arch}"
