kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/31ef701.tar.gz
  ref: 639abdfa0b663a1fae46985526782f70fe23c1f3f3c2f7dd0818f622653e6f05
  base-dir: kde-build-meta-31ef701b5b8494db582b05dfedae3315a90a0b0f

config:
  options:
    arch: "%{arch}"
