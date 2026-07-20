kind: manual
description: "Ensure systemd-boot and bootctl are included in the runtime domain"

build-depends:
- freedesktop-sdk.bst:components/systemd.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - install -Dm755 -t "%{install-root}%{bindir}" "%{bindir}/bootctl"
  - install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/boot/efi" "%{indep-libdir}/systemd/boot/efi/"*.efi
  - install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/boot/efi" "%{indep-libdir}/systemd/boot/efi/"*.stub
  - install -Dm755 -t "%{install-root}%{libdir}/systemd" "%{libdir}/systemd/"*.so

public:
  bst:
    overlap-whitelist:
    - "%{bindir}/bootctl"
    - "%{indep-libdir}/systemd/boot/efi/*"
    - "%{libdir}/systemd/*"
