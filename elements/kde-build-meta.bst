kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c4f4ca3.tar.gz
  ref: 5c3bf77f4406adbac12a782428ba0215b384147261315d04d5ff600c3a3a80fc
  base-dir: kde-build-meta-c4f4ca3e13b73a09e44588f4063084f74546e44b

config:
  options:
    arch: "%{arch}"
