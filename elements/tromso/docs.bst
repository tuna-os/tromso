kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: v2026.07-13-g61a8a34481fdf654ab69e21dab035fffb8c196ea
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: 632c01960b9da73b83077da37206c2df555c35986aa391dacfc644e81f875e7b

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
