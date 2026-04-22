kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/e5f9fce.tar.gz
  ref: fcf33fcad880395022c84ce90bb0d40b5b4645c274dce9dd9047a94ee97e2f29
  base-dir: kde-build-meta-e5f9fce92fa737a6880e18c73fc7021cb914be7d

config:
  options:
    arch: "%{arch}"
