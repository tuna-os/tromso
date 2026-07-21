kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: v2026.07-8-g570f59395b1ce144e423846928cb130c550d2ddc
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: 8b346ef46f3dcc5c3f077f7cfd06bd41f18f2f86efecc51fcaf20a0bff403083

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
