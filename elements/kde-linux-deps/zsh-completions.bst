kind: manual

sources:
- kind: git_repo
  url: github:zsh-users/zsh-completions.git
  track: '[0-9]*.[0-9]*.[0-9]*'
  ref: 0.35.0-0-g67921bc12502c1e7b0f156533fbac2cb51f6943d

config:
  build-commands: []

  install-commands:
  - |
    install -dm 755 %{install-root}%{datadir}/zsh/site-functions
    cp src/* %{install-root}%{datadir}/zsh/site-functions/

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''
