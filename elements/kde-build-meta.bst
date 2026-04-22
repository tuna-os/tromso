kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/966f09d.tar.gz
  ref: 8a7fe11170d87b263b9573716fcbcd0a177c8be320dc8c21ffd50159a78d7545
  base-dir: kde-build-meta-966f09dcf21444932f4d7ca6f4c92c54e19ad188

config:
  options:
    arch: "%{arch}"
