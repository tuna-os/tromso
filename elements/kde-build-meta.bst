kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/2be3772f7c3299bc7764222f8caf8ccc585999ec.tar.gz
  ref: 7afe34c4fded7eb0a59bf4dd21e82fd0efa631e70e77f5ab59062ebdfe397ac5
  base-dir: kde-build-meta-2be3772f7c3299bc7764222f8caf8ccc585999ec

config:
  options:
    arch: "%{arch}"
