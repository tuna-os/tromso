kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/aa9fb99.tar.gz
  ref: c8e5d40d71fb97efe783b4fc597d5c20abb572964618287196a8c4dac7575ff3
  base-dir: kde-build-meta-aa9fb99b63a43ca7a6847889c95d4d13d82a7e23

config:
  options:
    arch: "%{arch}"
