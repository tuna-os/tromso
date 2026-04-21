kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a00b722.tar.gz
  ref: 2c46d28f0a66e44ee22bbc660256f9eecb67a6a527d9c1eda99b86f6e4da0018
  base-dir: kde-build-meta-a00b7227ce5ccac625d8c8c8fc700c09ad341a7d

config:
  options:
    arch: "%{arch}"
