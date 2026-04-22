kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/a5a2d52.tar.gz
  ref: a67e04f422f4bcc9b7dc1775e6aff51a05b74565c4fd6e94bb0cee09f2d4c514
  base-dir: kde-build-meta-a5a2d52b96437d4eb239e6037171533df634ac24

config:
  options:
    arch: "%{arch}"
