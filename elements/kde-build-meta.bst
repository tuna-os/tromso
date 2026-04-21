kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9e22870.tar.gz
  ref: 1cbf224d19be81ca861664cf650d8834b1b0b1692affff5c3a2af62f7767fd13
  base-dir: kde-build-meta-9e22870afe8501879737300735867bdabcddfb8c

config:
  options:
    arch: "%{arch}"
