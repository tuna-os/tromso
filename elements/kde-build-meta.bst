kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/05ecd8a.tar.gz
  ref: 871346532d2507199f9fa820b64ae27a9dc183cc26a693944c6a350f7913999e
  base-dir: kde-build-meta-05ecd8a8feb08bfa3eeb209adfd8f70d14ee00d6

config:
  options:
    arch: "%{arch}"
