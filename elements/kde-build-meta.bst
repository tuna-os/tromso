kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a37dac7.tar.gz
  ref: 238ed3ea92c3f74de7051edb265e83bcc34a454b1e1b186e20e731977e7733f9
  base-dir: kde-build-meta-a37dac7fb8f91263e28443830d2c0e0938923b47

config:
  options:
    arch: "%{arch}"
