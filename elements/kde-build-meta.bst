kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/2be3772f7c3299bc7764222f8caf8ccc585999ec.tar.gz
  ref: d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed
  base-dir: kde-build-meta-2be3772f7c3299bc7764222f8caf8ccc585999ec

config:
  options:
    arch: "%{arch}"
