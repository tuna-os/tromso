kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/36945f5.tar.gz
  ref: 07e9e829b66f239d849d345c5b5397e5177cf182e8fd4d936afae119cfd7efc6
  base-dir: kde-build-meta-36945f5ad466ff7bb374d093bac1b632fc2d66a7

config:
  options:
    arch: "%{arch}"
