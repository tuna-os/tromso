kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9b1df3894.tar.gz
  ref: 9db6fa44f1f72bf21f26970730e21196c3ed56453589ddc4150bef85aec727b3
  base-dir: kde-build-meta-9b1df389454de41630a2d56885fb8c04ed2bc5ef

config:
  options:
    arch: "%{arch}"
