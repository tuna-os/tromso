kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0ac4a3e8d0a9c366b9fbef1cdb306de51d9c9d42.tar.gz
  ref: e51631ec29cc6cecb68be45ad1a7b88d4d209b3aea121dd5b7118cc4229fa18b
  base-dir: kde-build-meta-0ac4a3e8d0a9c366b9fbef1cdb306de51d9c9d42

config:
  options:
    arch: "%{arch}"
