kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/45ac35d.tar.gz
  ref: 07e70e886194192af20ab61a39c08522d7de86b4cb040a5aa4a79d23c0799203
  base-dir: kde-build-meta-45ac35d13370bab6ebea2e5928b96fbb06f5b8f9

config:
  options:
    arch: "%{arch}"
