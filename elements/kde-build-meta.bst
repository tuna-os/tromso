kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/482f655.tar.gz
  ref: cc3826b121e787e3f1600c1981873a1250dfea0cb79b8250298aa74ff5f028e3
  base-dir: kde-build-meta-482f655548daa0f93b8e654f48b2989aaa105f7f

config:
  options:
    arch: "%{arch}"
