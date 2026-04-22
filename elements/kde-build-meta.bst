kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/02a8725.tar.gz
  ref: 4cde59e06127ffd277e106d8f9fad2abe9ac010b81c6cda36d3d5f518ef3a245
  base-dir: kde-build-meta-02a872518e7099a7ad0f2ca3af412d4bdb00c4f3

config:
  options:
    arch: "%{arch}"
