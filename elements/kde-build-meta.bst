kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/7096cd9.tar.gz
  ref: 7caeae09f95f918a8f7b280ee2b55c7a5de55c50e845b808a92db20cfb2d02d8
  base-dir: kde-build-meta-7096cd93875a4ad3e3fcaa94bb92cc58576b26f8

config:
  options:
    arch: "%{arch}"
