kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/c1e9094.tar.gz
  ref: e2bf3232c589bfd7aa70f655b8afd8fffefd50838a01b1db82391e6bb44ae231
  base-dir: kde-build-meta-c1e909422c5ce841802fe725e9d44db974116cf6

config:
  options:
    arch: "%{arch}"
