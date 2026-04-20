kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a6d20d8bf5c49119c1da461f514d51adbef801d9.tar.gz
  ref: b7eda6ca6f85976a06b0939de2c80e34d1cfda2608d0101d024f303fac608765
  base-dir: kde-build-meta-a6d20d8bf5c49119c1da461f514d51adbef801d9

config:
  options:
    arch: "%{arch}"
