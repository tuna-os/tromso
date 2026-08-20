kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: local
  path: files/tromso/aurora-common
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: 83491b21a5972b14fe73201291c18f4a6ffe3ad4d1eb37b91f984bd4a70b3a65

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm0644 aurora.pdf "%{install-root}%{datadir}/doc/aurora/aurora.pdf"
    install -Dm0644 \
      system_files/shared/usr/share/applications/dev.getaurora.offline-docs.desktop \
      "%{install-root}%{datadir}/kglobalaccel/dev.getaurora.offline-docs.desktop"
  - "%{install-extra}"
