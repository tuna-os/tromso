kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/fc9f9d5.tar.gz
  ref: c53cb3d0f1148481d9377b8a1e4a110123930ad7131371080a71f7478004db4d
  base-dir: kde-build-meta-fc9f9d515cc6bbae6648677526fe2f3ee32d5ce9

config:
  options:
    arch: "%{arch}"
