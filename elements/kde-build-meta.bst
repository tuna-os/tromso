kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/14f6f52.tar.gz
  ref: 97cf39ef1525dda4d2cba2518bcf5e41e5bd87b71ebd5f90a3f5f8b6c4d576e7
  base-dir: kde-build-meta-14f6f52fa49dbad846831db02b4a31de9e3ae5b5

config:
  options:
    arch: "%{arch}"
