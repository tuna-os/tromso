kind: junction
description: Junction to hanthor/kde-build-meta (KDE Plasma 6 build metadata)

sources:
- kind: tar
  url: github:hanthor/kde-build-meta/archive/ff79a28.tar.gz
  ref: 6ec54ad398b326ea5add69cb1a43a47b97a7d6b11c2a9864a30130bc68c66d00
  base-dir: kde-build-meta-ff79a28483f5e9d514aae45dabca8e2fd7d90ea0

config:
  options:
    arch: "%{arch}"
