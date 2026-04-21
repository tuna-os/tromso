kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/9e094d9.tar.gz
  ref: 27335ded377ce90503c3552ee49be514b82dfa58f9a69ad956df942a9c2ce6ca
  base-dir: kde-build-meta-9e094d91c5a68513f9416c03ad69314460f10439

config:
  options:
    arch: "%{arch}"
