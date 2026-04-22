kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/4feb8dc.tar.gz
  ref: 54ead1a88414d9d437df66cc71176bdc711082021e0c0bc77325743444c2464f
  base-dir: kde-build-meta-4feb8dc5d6c2e88af34e0f189074bcb3358d2ca9

config:
  options:
    arch: "%{arch}"
