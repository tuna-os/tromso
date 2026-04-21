kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/94f3055.tar.gz
  ref: f528d33a5da1d3738a68803efaae08c4a69195f78ff702af40406456f6877ba6
  base-dir: kde-build-meta-94f3055215a84c1fb99cea0869aa86dc0253e0ca

config:
  options:
    arch: "%{arch}"
