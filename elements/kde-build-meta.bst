kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9fba3a4.tar.gz
  ref: a5df1782779d3037748df5568c94b75de1230c9eac130fc0ff718d59d34172f5
  base-dir: kde-build-meta-9fba3a47fdba588753e9a34d03b060cc474eedd6

config:
  options:
    arch: "%{arch}"
