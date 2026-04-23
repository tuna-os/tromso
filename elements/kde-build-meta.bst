kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/94b966b.tar.gz
  ref: 8a24ef1567000e0ec6256f5b5e68dcaa9e4c49c73e18d1ceb14901107a8b152b
  base-dir: kde-build-meta-94b966bd5315c649809d6848f353b96f28ff37e7

config:
  options:
    arch: "%{arch}"
