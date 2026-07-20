kind: meson
description: Library and daemon for configuring gaming mice (ratbagd)

sources:
- kind: tar
  url: github:libratbag/libratbag/archive/refs/tags/v0.18.tar.gz
  ref: 8a7f8bf00c21ef5ad534e2804ed537f2fc6521a3932dd822c438e561a85a1bcd

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/swig.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/libevdev.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/json-c.bst
- freedesktop-sdk.bst:components/json-glib.bst
- freedesktop-sdk.bst:components/libgudev.bst
- freedesktop-sdk.bst:components/dbus.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/libevdev.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/json-c.bst
- freedesktop-sdk.bst:components/json-glib.bst
- freedesktop-sdk.bst:components/libgudev.bst
- freedesktop-sdk.bst:components/dbus.bst

variables:
  meson-local: >-
    -Dtests=false
    -Ddocumentation=false
