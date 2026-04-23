kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a4bd2d7.tar.gz
  ref: ef8db1c009c0ad5a95467872b82c1ee1100f11aab6b78b0c01e7d098769ef3e4
  base-dir: kde-build-meta-a4bd2d72e21c72ea5e204febf35311a83b0345ba

config:
  options:
    arch: "%{arch}"
