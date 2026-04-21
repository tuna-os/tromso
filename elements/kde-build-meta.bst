kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/2d7f5b2.tar.gz
  ref: 946d65e604bd5e7f0ee166f6d26450a76e3b96401f9634411ae3c345dfabda42
  base-dir: kde-build-meta-2d7f5b2606ff9359995a09f8757cc369d65993fa

config:
  options:
    arch: "%{arch}"
