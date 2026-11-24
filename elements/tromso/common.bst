kind: manual
description: Common system files (vendored from get-aurora-dev/common, unaffiliated)

sources:
- kind: local
  path: files/tromso/aurora-common

depends:
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

public:
  bst:
    overlap-whitelist:
    - /etc/environment

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
