kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a473e73.tar.gz
  ref: 10e18ca69879eedd613b198cf112e2c484f95d29c40ce0cd08d2ef3b8cb33b48
  base-dir: kde-build-meta-a473e73f67a8c7ed29f4be91ad3efb4bdcde2003

config:
  options:
    arch: "%{arch}"
