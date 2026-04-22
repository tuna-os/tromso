kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/e860a45.tar.gz
  ref: 9c808cde3270335cda363518e9c35c9547afd6d40b6861e10dd867ab78232e7f
  base-dir: kde-build-meta-e860a457d346967da2dc567b4539011f116eaa6d

config:
  options:
    arch: "%{arch}"
