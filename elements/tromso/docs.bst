kind: manual
description: Aurora offline documentation PDF and launcher registration

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: a40eb75e00df196d264e09cc9022f642be4304f0
- kind: remote
  url: github_files:ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
  ref: 12ba7e1ef726a3d7320e7f6be370104722dbbab888d916c61b66e7d13e2ddfb4

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

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
