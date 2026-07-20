kind: manual
description: udev rules for Steam controllers and VR hardware

sources:
- kind: tar
  url: github:ValveSoftware/steam-devices/archive/refs/tags/v1.0.0.61.tar.gz
  ref: a6feec4e239e818985ef3a1939bc1e294537f8da9fb18ec07a1f5c18e3466ff5

build-depends:
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/systemd.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - install -Dm644 60-steam-input.rules -t %{install-root}$(pkg-config udev --variable udevdir)/rules.d
  - install -Dm644 60-steam-vr.rules -t %{install-root}$(pkg-config udev --variable udevdir)/rules.d
