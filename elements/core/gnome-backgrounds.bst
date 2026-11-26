kind: meson

sources:
- kind: git_repo
  url: gnome:gnome-backgrounds.git
  track: main
  ref: 50.0-0-gb688c27680e968afe0c314ff3fe45d0b39fb5e2f

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

runtime-depends:
- gnome-build-meta.bst:sdk/gdk-pixbuf.bst
- gnome-build-meta.bst:sdk/librsvg.bst

depends:
- gnome-build-meta.bst:sdk/glib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
