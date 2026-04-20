kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/58401b48f203bb81350b30c1d8b0cb10f53f2563.tar.gz
  ref: c441f7c76f11c93a3ea7c6775b3095015e5ae6bc4397355052e1860774fb9581
  base-dir: kde-build-meta-58401b48f203bb81350b30c1d8b0cb10f53f2563

config:
  options:
    arch: "%{arch}"
