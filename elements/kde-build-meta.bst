kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/abb267c.tar.gz
  ref: f6fa2bd07e3f05a780c370db440c95d71cceaa14f2e880506bcc28ac64740576
  base-dir: kde-build-meta-abb267c6319434f84b61af2fd0151b0099c4917f

config:
  options:
    arch: "%{arch}"
