kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8968daf.tar.gz
  ref: 9c2d53d5fe67972f55f19d6bae2f32ad77e4d771e7cb42b382e751e1e74eed7c
  base-dir: kde-build-meta-8968daf398cf7939ddcf3a068c0b6ea2bed01cc5

config:
  options:
    arch: "%{arch}"
