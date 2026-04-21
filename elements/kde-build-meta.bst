kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/038db13.tar.gz
  ref: ebcf631c4471f8d8ea7685af07b2ac378c67887c6ca856becbe237096475aa4d
  base-dir: kde-build-meta-038db1381648a0abafa55e5c1fc9abfbd837e9a7

config:
  options:
    arch: "%{arch}"
