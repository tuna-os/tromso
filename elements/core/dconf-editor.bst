kind: meson

sources:
- kind: git_repo
  url: gnome:dconf-editor.git
  track: master
  ref: 49.0-25-gfa7abe310ff771e9e81541bc3f728f51586a024d

build-depends:
- gnome-build-meta.bst:sdk/vala.bst
- freedesktop-sdk.bst:components/desktop-file-utils.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- core-deps/dconf.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gtk+-3.bst
- gnome-build-meta.bst:core-deps/libhandy.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
