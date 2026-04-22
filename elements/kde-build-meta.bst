kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8d7b598.tar.gz
  ref: 06f6836a66ed3ed9c8e573fe48abc40fe0cc35243dfc5443babcdacc5fe4d3a7
  base-dir: kde-build-meta-8d7b598069c14b36d4c770a44b9cd0c49b61ca4f

config:
  options:
    arch: "%{arch}"
