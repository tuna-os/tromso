kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/4312dc0.tar.gz
  ref: 6bd81ac22a651552c0d54416688fffdc4891cc0ac92c3836b836136d9d374a6c
  base-dir: kde-build-meta-4312dc08e8c6419522987de50123e6b26c25f5e4

config:
  options:
    arch: "%{arch}"
