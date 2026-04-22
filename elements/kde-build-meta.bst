kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/3cf55aa.tar.gz
  ref: 29126d98763f716dea156b2cfd1986d151bcd4cc52299614be0a8b88e0214b8b
  base-dir: kde-build-meta-3cf55aa59f501f3cf4a8b6dd917a226e2c35bbc6

config:
  options:
    arch: "%{arch}"
