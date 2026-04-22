kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/87957b0.tar.gz
  ref: d1b57ba6bbab3f48d6d89e0b85a548049bc42f9a105d9be6075f82a7f93a1be2
  base-dir: kde-build-meta-87957b0fbd640a42d4ba4e4e96a14e93bbdd36f5

config:
  options:
    arch: "%{arch}"
