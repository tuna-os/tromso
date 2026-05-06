kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/567cefb.tar.gz
  ref: 235662dc1f3c11a9f11d265cfe60a519bc106eb4449d2a8d8f3cc0e34f902948
  base-dir: kde-build-meta-567cefbaa6f64f1136d60c01a46fbc7f676d7f3a

config:
  options:
    arch: "%{arch}"
