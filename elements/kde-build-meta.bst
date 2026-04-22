kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/da7ad90.tar.gz
  ref: da5704b91afa07a1a5fc022b033f2bf13070f1906296bdf1e2ee944f359e59b1
  base-dir: kde-build-meta-da7ad90dd4d6888be71dcb9f84a25f89e4d9b2c0

config:
  options:
    arch: "%{arch}"
