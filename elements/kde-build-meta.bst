kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/2aae70e.tar.gz
  ref: 0552fad557dfc39a6c2ecbb54d20c59e54e85b73c5695e3143c6ee1634b715ca
  base-dir: kde-build-meta-2aae70ef49f6b87b0d25f97ff70f72bc6bd06c2e

config:
  options:
    arch: "%{arch}"
