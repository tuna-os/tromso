kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/b0e59f2.tar.gz
  ref: 5fa52af44f5df905c71de3bc1245f5d4a904d68961de09ccd43dec8d3ae5ff10
  base-dir: kde-build-meta-b0e59f22da5b7618aa4398f2fad4ee2cba696ede

config:
  options:
    arch: "%{arch}"
