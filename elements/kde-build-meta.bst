kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/6b418d7.tar.gz
  ref: 35400a3969af92caae4b7506b1092788405b76ea517ffe6c5d8e869705c128ce
  base-dir: kde-build-meta-6b418d76bf2c785c7a10e2e9b4de69bd92c4cb28

config:
  options:
    arch: "%{arch}"
