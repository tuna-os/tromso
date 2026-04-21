kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0503f50.tar.gz
  ref: 8fa4fcb12cb4dc1f232970a7a092dbeb41bffc3f44093e3be6d21f6419321235
  base-dir: kde-build-meta-0503f50a778dc9a9502a4b535be6f40532e6ae86

config:
  options:
    arch: "%{arch}"
