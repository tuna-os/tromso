kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/695fec8.tar.gz
  ref: 40eb9cc6259664a77a969e2edf57204a7fa30ceb5221d5c0d322a19613e6d1ec
  base-dir: kde-build-meta-695fec8b2651255e087fe5b25e128ccd32b49739

config:
  options:
    arch: "%{arch}"
