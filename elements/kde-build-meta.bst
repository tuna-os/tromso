kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/728d6ad.tar.gz
  ref: 69845dc4c07059f762b25b00f4571914b3b1dd0dad425ba58a1bede8ab6dc2d4
  base-dir: kde-build-meta-728d6ada015a36c71697a11457399ab52cdd5ac4

config:
  options:
    arch: "%{arch}"
