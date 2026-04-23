kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/56af029.tar.gz
  ref: 384ae947f7c52ffd0e32dc8d1f46d6c8ae08d2e02ae0ac2de48856be2567ccfe
  base-dir: kde-build-meta-56af0290bca15f71011c3ad46959297c634dff6e

config:
  options:
    arch: "%{arch}"
