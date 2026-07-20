kind: manual
description: USB device mode-switching utility and device data (4G modems, etc.)

sources:
- kind: tar
  url: tar_https:www.draisberghof.de/usb_modeswitch/usb-modeswitch-2.6.2.tar.bz2
  ref: f7abd337784a9d1bd39cb8a587518aff6f2a43d916145eafd80b1b8b7146db66
  directory: usb-modeswitch
- kind: tar
  url: tar_https:www.draisberghof.de/usb_modeswitch/usb-modeswitch-data-20251207.tar.bz2
  ref: 0bb12d64aee5e467c31af61a53fb828ff7aa59c54a82ca85eeede4c5690bfa66
  directory: data

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/systemd.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/systemd.bst

variables:
  strip-binaries: ''

config:
  build-commands:
  - make -C usb-modeswitch
  install-commands:
  - install -Dm755 usb-modeswitch/usb_modeswitch '%{install-root}/usr/bin/usb_modeswitch'
  - install -Dm755 usb-modeswitch/usb_modeswitch_dispatcher.tcl '%{install-root}/usr/bin/usb_modeswitch_dispatcher'
  - install -Dm644 usb-modeswitch/usb_modeswitch.conf '%{install-root}/etc/usb_modeswitch.conf'
  - |
    udevdir=$(pkg-config udev --variable udevdir)
    install -Dm644 data/40-usb_modeswitch.rules -t "%{install-root}${udevdir}/rules.d/"
  - install -dm755 '%{install-root}/usr/share/usb_modeswitch'
  - cp -r data/usb_modeswitch.d/. '%{install-root}/usr/share/usb_modeswitch/'
