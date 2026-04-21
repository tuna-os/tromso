kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/4bd2031.tar.gz
  ref: daf31466c32c7bf4ae2c620f7a290b971f4e00d93606f5cc0054693b87273dfb
  base-dir: kde-build-meta-4bd2031d39dab671f51f0eae43b26cd60f774a6d

config:
  options:
    arch: "%{arch}"
