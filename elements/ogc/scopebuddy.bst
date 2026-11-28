kind: manual
description: ScopeBuddy, a start script for gamescope on the desktop

runtime-depends:
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/jq.bst
- freedesktop-sdk.bst:components/perl.bst
- ogc/gamescope.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - install -Dm755 -t '%{install-root}%{bindir}' bin/scopebuddy
  - ln -s scopebuddy '%{install-root}%{bindir}/scb'
  - install -Dm644 LICENSE '%{install-root}%{datadir}/licenses/ScopeBuddy/LICENSE'

sources:
# 1.5.1 and later commits of main.
- kind: git_repo
  url: github:OpenGamingCollective/ScopeBuddy.git
  ref: 44ab54e0fe9b16d54da65eeb9e1e535a5085189e
