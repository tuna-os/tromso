kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0878f8b.tar.gz
  ref: 2ab7a7040e738b7195112b5de5d47be6ca84001c4faf97490217a43e88af4e8b
  base-dir: kde-build-meta-0878f8bc66d9997adc33a4ca78f75e097ab8b833

config:
  options:
    arch: "%{arch}"
