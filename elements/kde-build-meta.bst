kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0008f36.tar.gz
  ref: af04da6642ccbcf18408f54b6a5613cdb1e07a07c42b1182b217645526d15600
  base-dir: kde-build-meta-0008f36c3c3b9dfa20f48b2748005960f4db138e

config:
  options:
    arch: "%{arch}"
