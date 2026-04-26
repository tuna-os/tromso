kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/1fe1b559c.tar.gz
  ref: 96cbcd3a3ae009b0a4ac9391b658dcf56bf92b267b94edb278f857faa8c462d1
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
