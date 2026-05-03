kind: manual
description: Bluefin common shared payload imported for Aurora layering parity

sources:
- kind: git_repo
  url: github:projectbluefin/common.git
  track: main
  ref: 93d75c3ad186ab3093cf2066cd00f891fba63d8f

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

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
