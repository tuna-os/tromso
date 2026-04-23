kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/61d0865.tar.gz
  ref: 42f52ee8d553fd68860a08a70eb5b08a7335193120b2269254a453e94bddf21a
  base-dir: kde-build-meta-61d08653dd4c93d4cb3416da7015b222f3d0d9d0

config:
  options:
    arch: "%{arch}"
