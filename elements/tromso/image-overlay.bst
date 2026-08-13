kind: manual
description: Aurora image overlay payload from ublue-os/aurora system_files/shared

sources:
- kind: git_repo
  url: github:ublue-os/aurora.git
  track: main
  ref: stable-20260811.1-5-g580e89b4cdb71202489992b7ed198a61a629f7b7

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    if [ -d system_files/shared/usr ]; then
      cp -r system_files/shared/usr/./ "%{install-root}%{prefix}/"
    fi
    if [ -d system_files/shared/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r system_files/shared/etc/./ "%{install-root}%{sysconfdir}/"
    fi
  - "%{install-extra}"
