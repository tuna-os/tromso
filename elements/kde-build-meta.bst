kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/54ffee4.tar.gz
  ref: 57dcdec2f9943a9763ccf23d609c2d1762f1e67bb78194b82d868130699a71dc
  base-dir: kde-build-meta-54ffee45965b784fe5cdbd504190893da8c0deda

config:
  options:
    arch: "%{arch}"
