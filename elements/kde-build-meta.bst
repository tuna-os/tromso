kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a8492b2.tar.gz
  ref: 5f39ea8cb3ca2249568937da6d8d4318def587a17b6561914399c112b657d6e6
  base-dir: kde-build-meta-a8492b2cb3ece4f397c3a971dc49203020a93dcf

config:
  options:
    arch: "%{arch}"
