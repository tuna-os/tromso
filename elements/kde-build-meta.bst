kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/132d005.tar.gz
  ref: d81eaa68b57aa4d6b092495985334a5c7c955774b9c964b39c09d2bebcca5e2a
  base-dir: kde-build-meta-132d0053c9d52d44d7581a4ff54facfaf7b52cc6

config:
  options:
    arch: "%{arch}"
