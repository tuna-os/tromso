kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/16cbfb5.tar.gz
  ref: 1f34498cdfbf35bd15036860c09b0ffe824ccd413c357baf21f14ee603e07df8
  base-dir: kde-build-meta-16cbfb54a3dec6aa84ddf9555964853b1efaca03

config:
  options:
    arch: "%{arch}"
