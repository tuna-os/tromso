kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/e2077d8.tar.gz
  ref: 7bd178740cfc50bb2a6f8e04f987bc57a5352e6416f071b112d76836d5a7deef
  base-dir: kde-build-meta-e2077d84fd79d45a751ec9500d1c3252d6227be2

config:
  options:
    arch: "%{arch}"
