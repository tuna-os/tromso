kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/7773ea6.tar.gz
  ref: 1408bad5cb63bab312b009893185d28dc517afb6ae3a41065edd4b1d8a50e025
  base-dir: kde-build-meta-7773ea653d64395ff6706ea8e666c78b7e94b963

config:
  options:
    arch: "%{arch}"
