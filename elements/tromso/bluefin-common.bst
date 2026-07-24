kind: manual
description: Bluefin common shared payload imported for Aurora layering parity

sources:
- kind: git_repo
  url: github:projectbluefin/common.git
  track: main
  ref: v2026.07-50-ge9a4324b97ef76407bf2760a01db2ea76cf32aca

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

public:
  bst:
    overlap-whitelist:
    - /etc/containers/policy.json

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
      rm -f "%{install-root}%{sysconfdir}/containers/policy.json"
    fi
  - "%{install-extra}"
