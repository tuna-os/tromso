kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/b5be52f.tar.gz
  ref: 480a0a3d4600e77800b281101d6089d7f01e0a974314165ff8848da679f17818
  base-dir: kde-build-meta-b5be52f099ac5042f8941be0f3fb1972508d5509

config:
  options:
    arch: "%{arch}"
