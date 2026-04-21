kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/7193e1e.tar.gz
  ref: 0a13378c4ae783661d93b4062c5d2f0962f4faaf7a781fc08024a8bb2a27c37e
  base-dir: kde-build-meta-7193e1eb358e249b30feb596614a7e39db380a8d

config:
  options:
    arch: "%{arch}"
