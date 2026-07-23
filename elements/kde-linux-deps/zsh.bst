kind: autotools
description: Z shell (zsh)

sources:
- kind: tar
  url: tar_https:www.zsh.org/pub/old/zsh-5.9.tar.xz
  ref: 9b8d1ecedd5b5e81fbf1918e876752a7dd948e05c1a0dba10ab863842d45acd5

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: >-
    --enable-zsh-secure-free
    --enable-multibyte
    --with-tcsetpgrp

config:
  configure-commands:
    (<):
    - |
      # GCC 15: zsh's 'static boolcodes[]' conflicts with ncurses extern 'boolcodes[]'.
      # Rename to zsh_boolcodes to avoid the conflict (static so only used in this file).
      sed -i 's/\bboolcodes\b/zsh_boolcodes/g' Src/Modules/termcap.c

  install-commands:
    (>):
    - |
      # freedesktop-sdk-stripper can't handle hard links.
      # zsh installs zsh and zsh-5.9 as hard links; break it with a copy.
      tmpf=$(mktemp)
      cp /buildstream-install/usr/bin/zsh "$tmpf"
      mv "$tmpf" /buildstream-install/usr/bin/zsh-5.9

public:
  bst:
    integration-commands:
    - echo %{bindir}/zsh >> /etc/shells
