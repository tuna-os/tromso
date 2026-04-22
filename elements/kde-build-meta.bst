kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8a1249c.tar.gz
  ref: f4ae523b6644078825d4406b8f93ca94623bf4ec56c0d1000cd3f318700778a0
  base-dir: kde-build-meta-8a1249c107a9e37c70be32dc0ee237f3f0aa639c

config:
  options:
    arch: "%{arch}"
