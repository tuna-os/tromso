kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/56b97ca.tar.gz
  ref: c374707a818eed4b0e6a08c84d16e34b5189e28b4ec2e0039e8e3579bf7ce557
  base-dir: kde-build-meta-56b97ca2b2bf532f903656088d44ccd1cbbd1625

config:
  options:
    arch: "%{arch}"
