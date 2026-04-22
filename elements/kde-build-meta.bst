kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a97bce1.tar.gz
  ref: f163dff87f2783c7f9401b5e296b4ef9e0ba00aacfc49ab76dd3848fd221aade
  base-dir: kde-build-meta-a97bce17b7422522a2e99fe759d20475ef595d8a

config:
  options:
    arch: "%{arch}"
