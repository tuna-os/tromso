kind: manual
description: Aurora image overlay payload from ublue-os/aurora system_files/shared

sources:
- kind: git_repo
  url: github:ublue-os/aurora.git
  track: main
  ref: stable-20260815.1-1-gd51ce2364c23b0f6f2f58b934f21f6c1f59ed445

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
