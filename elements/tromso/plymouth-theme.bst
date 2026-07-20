kind: manual
description: >-
  KDE Linux breeze-bgrt Plymouth theme + plymouthd defaults.
  Assets are maintained upstream in invent.kde.org/kde-linux/kde-linux under
  mkosi.extra/usr/share/plymouth (GPL-2.0-only OR GPL-3.0-only OR
  LicenseRef-KDE-Accepted-GPL). The kde-build-meta initramfs generator's
  50-plymouth module auto-includes plymouth once /usr/bin/plymouth exists,
  so depending on plymouth + this theme is all that's needed for a branded
  splash and graphical LUKS passphrase prompt.

sources:
- kind: git_repo
  url: kde:kde-linux/kde-linux.git
  track: master
  ref: 51c0706cebcc1cf2c270d037ae7ed417f44dd977

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    themes_src="mkosi.extra/usr/share/plymouth"
    install -d "%{install-root}%{datadir}/plymouth/themes"
    cp -a "${themes_src}/themes/breeze-bgrt" "%{install-root}%{datadir}/plymouth/themes/"
    install -m 0644 "${themes_src}/plymouthd.defaults" "%{install-root}%{datadir}/plymouth/plymouthd.defaults"
  - |
    # bootc-installed systems: boot with `splash` so plymouth shows the
    # graphical splash and LUKS passphrase prompt. Deliberately no `quiet` —
    # CI's serial-log assertions depend on boot messages.
    install -d "%{install-root}/usr/lib/bootc/kargs.d"
    printf 'kargs = ["splash"]\n' > "%{install-root}/usr/lib/bootc/kargs.d/50-splash.toml"
