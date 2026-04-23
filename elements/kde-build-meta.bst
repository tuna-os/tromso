kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/fa99971.tar.gz
  ref: 99d8491e14612d6a4319d0536c9e1e75fae029267ec20943d7154db789edf9ef
  base-dir: kde-build-meta-fa99971522141ed0156b2aefd397bfdf8de3a4ce

config:
  options:
    arch: "%{arch}"
