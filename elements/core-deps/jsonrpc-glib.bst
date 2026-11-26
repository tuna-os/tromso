kind: meson

sources:
- kind: git_repo
  url: gnome:jsonrpc-glib.git
  track: main
  ref: 3.44.2-3-g611c2e9b06ff284f69fde3f9374d61a253380dc0

build-depends:
- gnome-build-meta.bst:sdk/gobject-introspection.bst
- gnome-build-meta.bst:sdk/vala.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/json-glib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
