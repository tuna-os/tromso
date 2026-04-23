kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9cfef43.tar.gz
  ref: 709625ace0a0119246f3615c62df698d20b74839b56a5feb8ee735cb0fdffa04
  base-dir: kde-build-meta-9cfef43a3742639cf21de8e432d45716fe36bfe9

config:
  options:
    arch: "%{arch}"
