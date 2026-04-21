kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/40d61b6.tar.gz
  ref: d8e2206c1d22817f28cc80c62415e7e68bdd4728ce84bdce4fe7753110ca70c5
  base-dir: kde-build-meta-40d61b6e8da19c1962e7e4adf9e174d232b29c09

config:
  options:
    arch: "%{arch}"
