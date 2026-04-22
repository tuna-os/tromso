kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/18be6f1.tar.gz
  ref: 6c04e618cd263f5ac4759afd7a801f2980b59813fd04216bdde7583253318526
  base-dir: kde-build-meta-18be6f1ec512e3b402f18c3fe8d3986870cd5dfa

config:
  options:
    arch: "%{arch}"
