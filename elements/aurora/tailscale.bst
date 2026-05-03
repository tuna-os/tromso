kind: manual
description: Aurora Tailscale payload adapted from Dakota's Bluefin element

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: tailscale_pkgs:tailscale_1.96.4_amd64.tgz
      ref: a1cba18826b1f91cb25ef7f5b8259b5258339b42db7867af9269e21829ea78cc
  - arch == "aarch64":
      url: tailscale_pkgs:tailscale_1.96.4_arm64.tgz
      ref: a27249bc70d7b37a68f8be7f5c4507ea5f354e592dce43cb5d4f3e742b313c3c

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/sed.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 -t "%{install-root}%{bindir}" tailscale tailscaled
  - |
    sed -e 's|/usr/sbin/tailscaled|/usr/bin/tailscaled|g' \
        -e '/^EnvironmentFile=/d' \
        systemd/tailscaled.service > tailscaled.service.patched
    sed -i '/^\[Service\]/a Environment=FLAGS=' tailscaled.service.patched
    sed -i '/^\[Service\]/a Environment=PORT=41641' tailscaled.service.patched
    install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/system" tailscaled.service.patched
    mv "%{install-root}%{indep-libdir}/systemd/system/tailscaled.service.patched" \
       "%{install-root}%{indep-libdir}/systemd/system/tailscaled.service"
  - |
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/systemd/system-preset/80-tailscale.preset" <<'PRESET'
    enable tailscaled.service
    PRESET
  - |
    %{install-extra}
