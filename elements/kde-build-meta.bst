kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/4519b18.tar.gz
  ref: c3ef7b7b083b44370e262b5434831af4aa85e88e752b094f3caa9dd303b9b40b
  base-dir: kde-build-meta-4519b18372c8faaaa8ff57ec4dad591dcab95e36

config:
  options:
    arch: "%{arch}"
