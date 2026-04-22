kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/b65f9db.tar.gz
  ref: b3dea705c1517cf4666fe391bc217ddb638758ac1a86adfbfca5043ca15a0ce7
  base-dir: kde-build-meta-b65f9dbac377162dead2d38b92bb04d695c2b34a

config:
  options:
    arch: "%{arch}"
