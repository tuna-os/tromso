kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f1ad586.tar.gz
  ref: bb4e6abe1a23129f208f686188612d377fa99385375476c92b6934fdac73325b
  base-dir: kde-build-meta-f1ad58615d7852af9ad3f0758192dd3a85ca013b

config:
  options:
    arch: "%{arch}"
