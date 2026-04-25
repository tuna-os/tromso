kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/ca47f8b.tar.gz
  ref: 8024d05a1a8e1d53d6baa09ab62e7a3f10fa8efd90cf0efc5e6f45bf84eecc86
  base-dir: kde-build-meta-ca47f8b83a3ba1eec77ac933e70acf6f0e6e8dfe

config:
  options:
    arch: "%{arch}"
