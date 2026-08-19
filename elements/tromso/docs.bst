kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: local
  path: files/tromso/aurora-common
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: bd1ec9b99efa047fe16dcac000d1d605e9b8997492d1d4c49b4d4217faca8438

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
