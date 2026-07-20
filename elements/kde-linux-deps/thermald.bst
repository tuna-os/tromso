kind: autotools

sources:
- kind: git_repo
  url: github:intel/thermal_daemon.git
  track: 'v2.*'
  ref: v2.5.9-0-g143d6570177212b879427e190625e1ac5489b0b9

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/gtk-doc.bst

depends:
- kde-linux-deps/upower.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/libxml2.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/libgudev.bst
- freedesktop-sdk.bst:components/libevdev.bst
- freedesktop-sdk.bst:components/libnl.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: >-
    --disable-werror
    --disable-gtk-doc
  autogen: ./autogen.sh
