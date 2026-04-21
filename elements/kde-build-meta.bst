kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f6f34ec.tar.gz
  ref: e494bbd79fee146b112f8697aea305c7b06b23c90d88a32909f03a324ccc4486
  base-dir: kde-build-meta-f6f34eca416848d1ba9728904bcc4d7c23b37fb9

config:
  options:
    arch: "%{arch}"
