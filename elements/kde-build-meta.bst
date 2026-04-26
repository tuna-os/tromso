kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0abe0bb64.tar.gz
  ref: 9d2a187bfd6cf58f4457c2bf00373295ef0b08ff188b91723fda4e2e54309666
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
