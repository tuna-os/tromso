kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8568dd8216c2b9c63a8e0156e2cd6d9e4b99666c.tar.gz
  ref: 4cfbcf2100d3a0e75b7f787872f6cb5a062fbc96d4c8661565fa89d58efc2111
  base-dir: kde-build-meta-8568dd8216c2b9c63a8e0156e2cd6d9e4b99666c

config:
  options:
    arch: "%{arch}"
