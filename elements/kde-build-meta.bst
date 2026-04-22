kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/cf1fdc7.tar.gz
  ref: 85ec87488f666393c1b3840f88f8740d3511dc9f32ff4c60a9ebd22784203197
  base-dir: kde-build-meta-cf1fdc78563a9e49641d2cb8b50d83824a44d926

config:
  options:
    arch: "%{arch}"
