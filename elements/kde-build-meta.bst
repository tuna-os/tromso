kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/845715f.tar.gz
  ref: 57163090d9d4502e317d6b9b98d99f4ae0dfa0f23bff4cd10952c273cc854815
  base-dir: kde-build-meta-845715f098b33a827ded2583a5d26b69771856cc

config:
  options:
    arch: "%{arch}"
