kind: meson

sources:
- kind: git_repo
  url: freedesktop:upower/upower.git
  track: 'v*'
  ref: v1.91.2-0-g17f9e8dc5a967fde13be688634a465c71fb79dd0

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/systemd.bst

depends:
- freedesktop-sdk.bst:components/libgudev.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/polkit-gobject.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  meson-local: >-
    -Dgtk-doc=false
    -Dman=false
    -Dintrospection=disabled
    -Didevice=disabled
