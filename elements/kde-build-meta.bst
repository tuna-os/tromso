kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/1128c23.tar.gz
  ref: 65cd396427b165c390ae279534ca43ef5eac028d30dd168a13a8b742c38c5037
  base-dir: kde-build-meta-1128c232c3b2c2b2058db8be0969fcdff833b652

config:
  options:
    arch: "%{arch}"
