kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/be75673.tar.gz
  ref: 70233c8b652e8401b05b7704d8758ea4b74308ec45fbb4e7147c04212f34a932
  base-dir: kde-build-meta-be7567396cfa8369d3caf3095cc6f8397132baac

config:
  options:
    arch: "%{arch}"
