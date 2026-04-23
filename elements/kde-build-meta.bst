kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/5b662aa.tar.gz
  ref: 9ab7d478c451aaf15f2c38fa0f6bac9dc8e84f0587d146da95a8953115c3cfa0
  base-dir: kde-build-meta-5b662aacc28068a9e04a2b9906d08ff5f70a89b6

config:
  options:
    arch: "%{arch}"
