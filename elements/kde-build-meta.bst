kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/1b61263f2.tar.gz
  ref: 5ccd5d9c044c302afae57115870d9836858dbe19ac48fdf1d71d61247aa14e33
  base-dir: kde-build-meta-1b61263f2792edb03107ee8983913aaea22cf5f5

config:
  options:
    arch: "%{arch}"
