kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9a5a70d.tar.gz
  ref: 6448c4ca2cac39434f9a021165d4636f2003dcba7c221bef9b44afa58bc509fe
  base-dir: kde-build-meta-9a5a70d5382b2d74745651e6c2ee0cefbf035d3c

config:
  options:
    arch: "%{arch}"
