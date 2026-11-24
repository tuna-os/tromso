kind: manual
description: Bluefin common shared payload imported for upstream layering parity

sources:
- kind: git_repo
  url: github:projectbluefin/common.git
  track: main
  ref: v2026.11-75-g7e89b5e0dfd0fb7550ee671b7718c6e365dfb974
- kind: local
  path: files/tromso/audit

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

build-depends:
- freedesktop-sdk.bst:components/findutils.bst
- freedesktop-sdk.bst:components/grep.bst

public:
  bst:
    overlap-whitelist:
    - /etc/containers/policy.json

variables:
  strip-binaries: ""

config:
  install-commands:
  # This element tracks projectbluefin/common's main branch and track-bst-sources.yml
  # automerges ref bumps. Fail when the payload adds a sensitive path nobody reviewed.
  - |
    sh check-upstream-payload.sh bluefin-common-paths.txt bluefin-common-stripped.txt
  - |
    if [ -d system_files/shared/usr ]; then
      cp -r system_files/shared/usr/./ "%{install-root}%{prefix}/"
    fi
    if [ -d system_files/shared/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r system_files/shared/etc/./ "%{install-root}%{sysconfdir}/"
      rm -f "%{install-root}%{sysconfdir}/containers/policy.json"
      # The upstream bootc upgrade NOPASSWD grant conflicts with the installed
      # image's sudo policy; privileged-setup handles upgrades through polkit.
      rm -f "%{install-root}%{sysconfdir}/sudoers.d/001-bootc"
    fi
  - "%{install-extra}"
