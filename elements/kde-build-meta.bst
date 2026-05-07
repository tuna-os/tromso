kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/0a82990.tar.gz
  ref: 125979204137514d2a139766f8edd4bcb12d1e85c4d5d0352dd872b0b9a1f038
  base-dir: kde-build-meta-0a82990f9461cce8dea9c0dfbc0c6081d6dc5919

config:
  options:
    arch: "%{arch}"
