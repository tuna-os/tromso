kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/fb56bfb.tar.gz
  ref: 1f60f59a55e6179f38928d62ccacd4aac7f0953e863ebd6149f90e74566b0080
  base-dir: kde-build-meta-fb56bfb28c1cbeaf120eb11d1826e326462c60ee

config:
  options:
    arch: "%{arch}"
