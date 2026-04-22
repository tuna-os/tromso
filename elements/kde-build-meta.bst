kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/3db10ac.tar.gz
  ref: 318025b6b31bb8e632370e81b2c914f8b0093630522aa437579c8d6c1c3bfe78
  base-dir: kde-build-meta-3db10ac5c21f0cd0b3f4611a1a13756113baf94f

config:
  options:
    arch: "%{arch}"
