kind: manual
description: Aurora image overlay payload from ublue-os/aurora system_files/shared

sources:
- kind: git_repo
  url: github:ublue-os/aurora.git
  track: main
  ref: 3726a5eca00101ee725b0f52c65572bf6872dbdd

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

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
