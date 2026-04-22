kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/69ffc99.tar.gz
  ref: 7dcd3391311f20524c0f9465727ba89037112733d7d29aa792b321e2a175943b
  base-dir: kde-build-meta-69ffc9910524095d74fdf20384ac30f2c21187c4

config:
  options:
    arch: "%{arch}"
