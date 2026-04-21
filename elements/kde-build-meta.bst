kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/38943ad.tar.gz
  ref: 6ecaa314e99860bde61c8c64d254ac234f1bfff6a8de7cf225ca756b867a4c12
  base-dir: kde-build-meta-38943ad1c8ab5b367ed86dd6706c37ca5c431fcd

config:
  options:
    arch: "%{arch}"
