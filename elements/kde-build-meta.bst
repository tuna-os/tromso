kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/63e5d0b05.tar.gz
  ref: 966f6aac2c70176e3a3df64e6cecdf7fbbe6276a81afba697a3e9a00d1b085d1
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
