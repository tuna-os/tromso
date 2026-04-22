kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/abf84ca.tar.gz
  ref: 2541ce67367d36601b6d2ff3f642bbf8bc5d4bfc3b3062ac12ddea19cc37a67c
  base-dir: kde-build-meta-abf84ca83d739faa79a58fdc7f52a106fae572d9

config:
  options:
    arch: "%{arch}"
