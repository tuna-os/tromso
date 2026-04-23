kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/d8b6cd7.tar.gz
  ref: f8c1f5ab9f4fe09e00e31790dd6ea97325444ec621656d58e2eb717661909a60
  base-dir: kde-build-meta-d8b6cd7c21ebeffb400dea4d0e7383937ca96518

config:
  options:
    arch: "%{arch}"
