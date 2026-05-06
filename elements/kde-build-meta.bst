kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/957829f.tar.gz
  ref: 43c8b4700515810ddfbf6a459e761d297acb0daba2a74ca81095958695ba6747
  base-dir: kde-build-meta-957829fcbd916e2c2b9afc9382a7d82e65ce89f4

config:
  options:
    arch: "%{arch}"
