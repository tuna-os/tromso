kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/255e6ef.tar.gz
  ref: 0050b4c959d0959c8bb9558ae7e7000702cc9acdf63bd7372f116f4760810901
  base-dir: kde-build-meta-255e6eff683ddbc94bf2014b2d29063e3b9a4df8

config:
  options:
    arch: "%{arch}"
