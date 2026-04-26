kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/70f9a415c.tar.gz
  ref: 389d514aa0010162b9f9a317466237d801b49e70e7589eb219e78c8305075ece
  base-dir: kde-build-meta-*

config:
  options:
    arch: "%{arch}"
