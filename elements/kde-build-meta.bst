kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/43fc37a.tar.gz
  ref: cbb0fa9783663631b0735c2231d18441e02d484ef85d3203a74a99ee2b8ef1af
  base-dir: kde-build-meta-43fc37a224d360eb52f135e7164ea4012f384132

config:
  options:
    arch: "%{arch}"
