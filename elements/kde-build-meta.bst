kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/412d542.tar.gz
  ref: 7445c6a52f08827d494d62b9c2aa00c1a5304aabf633841735853a419e0b44d1
  base-dir: kde-build-meta-412d542b540870daa54c94fb30f1eac9e94bedf4

config:
  options:
    arch: "%{arch}"
