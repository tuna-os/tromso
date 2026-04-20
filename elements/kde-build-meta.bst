kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0962838c7f9b4288d41e42187907984cd5dc484c.tar.gz
  ref: f7bfb2ce93d6e28f4151e785524e12bd4ab3aadee0ca88a47b4525422ab7a07a
  base-dir: kde-build-meta-0962838c7f9b4288d41e42187907984cd5dc484c

config:
  options:
    arch: "%{arch}"
