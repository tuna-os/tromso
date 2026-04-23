kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/5ba8a3e.tar.gz
  ref: b50a82de60f535c36ec595b7ecaf43864692d85d945874bdcc3d613d72f51846
  base-dir: kde-build-meta-5ba8a3e906e50a87a8a424f0f78c95b60ed4783b

config:
  options:
    arch: "%{arch}"
