kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/707f5cc.tar.gz
  ref: 38b3a12c303492d309d32886b9b5a39ec3bae58d66ad8c77241c1d1ef0cda9ff
  base-dir: kde-build-meta-707f5cc1703d267e63b91fb6f290fbe1f93de5c9

config:
  options:
    arch: "%{arch}"
