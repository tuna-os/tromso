kind: manual
description: English US spell check dictionary for Hunspell

sources:
- kind: git_repo
  url: github:LibreOffice/dictionaries.git
  ref: e4ad1862342d7e1365978499ca951ae4788c9dc0

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - install -Dm644 en/en_US.dic '%{install-root}%{datadir}/hunspell/en_US.dic'
  - install -Dm644 en/en_US.aff '%{install-root}%{datadir}/hunspell/en_US.aff'
  - install -d '%{install-root}%{datadir}/myspell'
  - ln -sf ../hunspell/en_US.dic '%{install-root}%{datadir}/myspell/en_US.dic'
  - ln -sf ../hunspell/en_US.aff '%{install-root}%{datadir}/myspell/en_US.aff'
