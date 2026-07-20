kind: manual

sources:
- kind: git_repo
  url: github:zsh-users/zsh-syntax-highlighting.git
  track: '[0-9]*.[0-9]*.[0-9]*'
  ref: 0.8.0-0-gdb085e4661f6aafd24e5acb5b2e17e4dd5dddf3e

config:
  build-commands: []

  install-commands:
  - |
    install -Dm 644 zsh-syntax-highlighting.zsh \
      %{install-root}%{datadir}/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    cp -r highlighters %{install-root}%{datadir}/zsh/plugins/zsh-syntax-highlighting/

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''
