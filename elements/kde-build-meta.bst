kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0e2e666.tar.gz
  ref: 812299d29463d6eb7064d58e12155400e10ab573906a7d8c1f470072ea6e814f
  base-dir: kde-build-meta-0e2e6662e87da25a66c4da222504d3ce0813657e

config:
  options:
    arch: "%{arch}"
