kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/3f54b58.tar.gz
  ref: f581eb1f618a731b51c59fa8b5aee4e13192c034bb7002314d51e2a383f7d721
  base-dir: kde-build-meta-3f54b58af0d2cfd0b5d0d4623247255316d36114

config:
  options:
    arch: "%{arch}"
