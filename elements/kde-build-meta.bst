kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/1e3426e.tar.gz
  ref: 11325da65990a9fa6526de9e802650ec378de8d80614473d80f6d06bae978067
  base-dir: kde-build-meta-1e3426e

config:
  options:
    arch: "%{arch}"
