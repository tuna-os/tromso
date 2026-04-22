kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/b1e8b06.tar.gz
  ref: 41d2755e13d4d2bc019aae02ebc0c395121fd684e19b3186313643b0de617c3f
  base-dir: kde-build-meta-b1e8b068707572d7abde32e6649b96ca9da4b554

config:
  options:
    arch: "%{arch}"
