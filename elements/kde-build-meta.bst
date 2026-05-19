kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/2aae70ef49f6b87b0d25f97ff70f72bc6bd06c2e.tar.gz
  ref: 21b0f269f141c18431f855a78cc2c6f9c30167b8b1765256f1e3a735f42cbdaa
  base-dir: kde-build-meta-2aae70ef49f6b87b0d25f97ff70f72bc6bd06c2e

config:
  options:
    arch: "%{arch}"
