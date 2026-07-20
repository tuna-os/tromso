# SPDX-License-Identifier: MIT

kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - |
    install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/system" create-user.service
    install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/system" plasma.service
    install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/system-preset/" 50-plasma.preset

sources:
- kind: local
  path: elements/kde/config
