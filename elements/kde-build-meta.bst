kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/5bd9d07.tar.gz
  ref: dd9d0f42eb6d640b929902ca2cc3a772842559d0438248f9aa69261ff68f10df
  base-dir: kde-build-meta-5bd9d07273ee48a8cf141373f9e8c2fa1c530477

config:
  options:
    arch: "%{arch}"
