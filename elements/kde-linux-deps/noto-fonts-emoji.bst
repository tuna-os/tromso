kind: manual
description: Noto Color Emoji font

sources:
- kind: tar
  url: tar_https:github.com/googlefonts/noto-emoji/archive/refs/tags/v2.051.tar.gz
  ref: 04f3d1e5605edebebac00a7a0becb390a4a3ead015066905b27935b30c18e745

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - install -Dm644 fonts/NotoColorEmoji.ttf '%{install-root}%{datadir}/fonts/noto/NotoColorEmoji.ttf'
