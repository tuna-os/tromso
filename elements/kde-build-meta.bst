kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a07c8f4.tar.gz
  ref: 84e69f3ed472a2b059180f17645ecb0b266ec4ddc6738c1816eee77c5325e943
  base-dir: kde-build-meta-a07c8f44e599fcfe1c38778a28225d123af9dfaf

config:
  options:
    arch: "%{arch}"
