kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/cfeb91e.tar.gz
  ref: c389c2104644dc7f2520b41de53cf0477e7fe69d1ab1288a9b3506a664568b8f
  base-dir: kde-build-meta-cfeb91e9d540685198891b62729448d345bc56f6

config:
  options:
    arch: "%{arch}"
