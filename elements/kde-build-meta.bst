kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/8307c0a.tar.gz
  ref: 9cb85b09658a9bac4ee9d3879d3093549cf53899c4d0396eeb1a667f858207df
  base-dir: kde-build-meta-8307c0ada82b1209ad93cf5311fd10a4077dd629

config:
  options:
    arch: "%{arch}"
