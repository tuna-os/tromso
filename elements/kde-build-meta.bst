kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/3007b4dc9967e97424755096b79ff8c005b4dd70.tar.gz
  ref: 4dd5f013fabe017acce569b8cb2c468cafe56435b5572a04036a8c4a3dbc84a2
  base-dir: kde-build-meta-3007b4dc9967e97424755096b79ff8c005b4dd70

config:
  options:
    arch: "%{arch}"
