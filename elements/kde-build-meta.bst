kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/1bfb2d2.tar.gz
  ref: c0d6422dcf61165699abeeda2a2928978911025d324f273de6e42f107a2585ce
  base-dir: kde-build-meta-1bfb2d217b6cd612b689d76abc0df9a432f87a18

config:
  options:
    arch: "%{arch}"
