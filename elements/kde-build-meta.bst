kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/10c6ee8.tar.gz
  ref: 96fa216b00512f0ef3fc99442f34fee41d0d1462f1c3f0d7b48c9f2542163621
  base-dir: kde-build-meta-10c6ee8ed75538debb4e58b82e553330a762fb14

config:
  options:
    arch: "%{arch}"
