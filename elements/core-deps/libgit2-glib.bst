kind: meson
sources:
- kind: git_repo
  url: gnome:libgit2-glib.git
  track: master
  ref: v1.2.1-1-gca9e9065f4a267e8922da42d9ca9b9170bc9c145
build-depends:
- gnome-build-meta.bst:sdk/gobject-introspection.bst
- gnome-build-meta.bst:sdk/vala.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
depends:
- core-deps/libgit2.bst
- core-deps/libssh2.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/pygobject.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
