kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a235bc4.tar.gz
  ref: 4a35132658552280601f6306af5817cebd80084721d35a9e4bae47dbf2871abb
  base-dir: kde-build-meta-a235bc43bdf45196e7e385b8eeecfe00a8c7c0e1

config:
  options:
    arch: "%{arch}"
