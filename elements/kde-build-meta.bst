kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9932f38.tar.gz
  ref: 0f4baace4a24d539a5360eb62ed541412b5fba4282384f567b3d673fea7dc67e
  base-dir: kde-build-meta-9932f3892ba09aa6063c9e06ee2c61f016ab4a89

config:
  options:
    arch: "%{arch}"
