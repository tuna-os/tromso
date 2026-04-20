kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/463485c.tar.gz
  ref: 65336e5257e3c9f387fa65564c7f76e43a217ae4b56a4f1be6d825572455d420
  base-dir: kde-build-meta-463485cf1552fda269d5e63babc2174712a0829a

config:
  options:
    arch: "%{arch}"
