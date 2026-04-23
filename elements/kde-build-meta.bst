kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f4375e5.tar.gz
  ref: 776688e36f6b60c4660d701f24fdccffc9d15583209ac75b327423f25c379b89
  base-dir: kde-build-meta-f4375e53ea442b7a85eea08a73f27cc7a64e09da

config:
  options:
    arch: "%{arch}"
