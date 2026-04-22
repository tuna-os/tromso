kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/d56895a.tar.gz
  ref: 03445206fd927232881e5dee275993b0b5b964c230bb37aeb7c085be936f3e60
  base-dir: kde-build-meta-d56895af55f35370c27f2ac99ab5243186f3d86e

config:
  options:
    arch: "%{arch}"
