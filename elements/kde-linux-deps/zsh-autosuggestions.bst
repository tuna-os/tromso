kind: manual

sources:
- kind: git_repo
  url: github:zsh-users/zsh-autosuggestions.git
  track: 'v*'
  ref: v0.7.1-0-ge52ee8ca55bcc56a17c828767a3f98f22a68d4eb

config:
  build-commands: []

  install-commands:
  - |
    install -Dm 644 zsh-autosuggestions.zsh \
      %{install-root}%{datadir}/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''
