kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/082fcf3.tar.gz
  ref: ec0f08298393b65bb9794bedb571106db0aaae3ef2df3ed6310d7b244943a0ee
  base-dir: kde-build-meta-082fcf3a2c9aaa938ab305a59f3b6acbcaaabaed

config:
  options:
    arch: "%{arch}"
