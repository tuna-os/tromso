kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a2e951827.tar.gz
  ref: c56bde6cfd76021218322482c912fd54365e252c0d4c4a35e0e64961c51f78a4
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
