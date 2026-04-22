kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c184110.tar.gz
  ref: f300d3dcc19855341d966fdc0cd54f871e755aa85fac1f1a22e5c5cb08dea2e8
  base-dir: kde-build-meta-c184110b236a0998c4a6d66e9ad8b572867d19de

config:
  options:
    arch: "%{arch}"
