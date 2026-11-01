kind: manual
description: >-
  Original Tromso identity artwork by TunaOS: icon, wordmark, and wallpaper
  asset. It is separate from KDE and Aurora artwork.

sources:
- kind: local
  path: branding/tromso

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
  - install -Dm644 tromso-logo.svg '%{install-root}%{datadir}/icons/hicolor/scalable/apps/tromso-logo.svg'
  - install -Dm644 tromso-wordmark.svg '%{install-root}%{datadir}/tunaos/branding/tromso-wordmark.svg'
  - install -Dm644 tromso-wallpaper.svg '%{install-root}%{datadir}/tunaos/branding/tromso-wallpaper.svg'
  - install -Dm644 tromso-wallpaper.png '%{install-root}%{datadir}/backgrounds/TunaOS/Tromso/tromso-wallpaper.png'
  - '%{install-extra}'

variables:
  strip-binaries: ''
