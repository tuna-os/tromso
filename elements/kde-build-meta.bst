kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/6fe2ccf.tar.gz
  ref: 579427c90405bdadc10f00b35f622b199f4382a94d3a8a2b83ed5876b4a690ab
  base-dir: kde-build-meta-6fe2ccfa4818aa0e8eb36cc761e03746a170eefb

config:
  options:
    arch: "%{arch}"
