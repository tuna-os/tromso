kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/ecc0531.tar.gz
  ref: 6660c20b9c13c01327488b6b69a3a3ca06510657320459da423ceb2675705e16
  base-dir: kde-build-meta-ecc0531247ade9d4c959473974241e719e45b5fc

config:
  options:
    arch: "%{arch}"
