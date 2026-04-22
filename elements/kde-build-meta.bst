kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f8b1d67.tar.gz
  ref: 2c98044c6f27df4ba576cb945584376b9e71b3d474a0d31dc89967f2b066cf52
  base-dir: kde-build-meta-f8b1d67dd33d895ce0da914e22c7c40dd6cd6b15

config:
  options:
    arch: "%{arch}"
