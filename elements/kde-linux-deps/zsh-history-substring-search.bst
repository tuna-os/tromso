kind: manual

sources:
- kind: git_repo
  url: github:zsh-users/zsh-history-substring-search.git
  track: 'v*'
  ref: v1.1.0-0-g400e58a87f72ecec14f783fbd29bc6be4ff1641c

config:
  build-commands: []

  install-commands:
  - |
    install -Dm 644 zsh-history-substring-search.zsh \
      %{install-root}%{datadir}/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''
