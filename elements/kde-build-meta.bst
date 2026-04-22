kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/92b9ff6.tar.gz
  ref: 455040318a99a40e20ebb3589d31fe94fd949af12f0d63150e36e877334b68ae
  base-dir: kde-build-meta-92b9ff693a135935a233a7c43e8d8cb5e47cc39d

config:
  options:
    arch: "%{arch}"
