kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/cd37fbc.tar.gz
  ref: 34b7c75429cf6af8156187a45e62ac9a62fda3e38e089ff5afc4098a1b68a311
  base-dir: kde-build-meta-cd37fbc5871f7c7d368b8cb1b744644f7d731d55

config:
  options:
    arch: "%{arch}"
