kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/83790f9.tar.gz
  ref: a337aca2414032f4e2f563f13902ea8a672d2bd8fa95d3bcdc05924201c4ded4
  base-dir: kde-build-meta-83790f9e7164653e2dbf3f3c4d5ba8997f16e6f7

config:
  options:
    arch: "%{arch}"
