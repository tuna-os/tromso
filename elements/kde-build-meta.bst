kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/5aa6dcf.tar.gz
  ref: ba956a676a4018815cfac485d4031322c6420ecad2c757ec43406b6fe3b0405b
  base-dir: kde-build-meta-5aa6dcfe75d3c4e61270def00e7873580bfc5014

config:
  options:
    arch: "%{arch}"
