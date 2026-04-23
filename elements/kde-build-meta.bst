kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a5d7526.tar.gz
  ref: aa47ca2cd40fde098ac7e6e9b5e11faea82b2a15d932b4f1333a9b9a42380022
  base-dir: kde-build-meta-a5d75263f74dd6ac1abdff187bb1c4719774dadf

config:
  options:
    arch: "%{arch}"
