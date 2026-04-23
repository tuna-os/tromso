kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/b7f963f.tar.gz
  ref: e27c6a186370559a0e11794100eee89a87a6fcf6f7e6261960865a8e92b4ad3f
  base-dir: kde-build-meta-b7f963f825d5e77db744687746408cabdecbf850

config:
  options:
    arch: "%{arch}"
