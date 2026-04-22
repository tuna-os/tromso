kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/529cd14.tar.gz
  ref: a0911ede5d2ee1b699a754259cfe616796199e90eac8391231cad2aaadff1cb2
  base-dir: kde-build-meta-529cd140ae5530c3260538fea5685bd9bf71226b

config:
  options:
    arch: "%{arch}"
