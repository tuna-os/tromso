kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: v2026.08-4-gd49c0ce6bee80147cd18045bdf21b313245b843d
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: b6af1a58ea6397f0c893a2a726d40dc511d56bb76af28a0d8286cce93cce8472

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
