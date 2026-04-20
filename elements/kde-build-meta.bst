kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f3d26bc9c.tar.gz
  ref: 42b949c29dd0a17ffcb5e3b3e4c1d0cbadffef1e2454fa4159db7ecfb2728071
  base-dir: kde-build-meta-f3d26bc9c4ef8779d25b2c38bf81c438b846036f

config:
  options:
    arch: "%{arch}"
