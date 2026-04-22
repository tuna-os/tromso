kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/f954859.tar.gz
  ref: 03e1c6b305e80bcbb5592df2e19511c807323df690ea1c7b55192bcfe6e59803
  base-dir: kde-build-meta-f954859d033735fa0758cbd73b9c12707ccae285

config:
  options:
    arch: "%{arch}"
