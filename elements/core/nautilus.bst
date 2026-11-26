kind: meson

sources:
- kind: git_repo
  url: gnome:nautilus.git
  track: main
  ref: 50.0-85-g696ec02f29a4d32c6fb7579556bab49ded8be101

build-depends:
- gnome-build-meta.bst:sdk/blueprint-compiler.bst
- gnome-build-meta.bst:sdk/gobject-introspection.bst
- freedesktop-sdk.bst:components/desktop-file-utils.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

runtime-depends:
- core-deps/xdg-user-dirs-gtk.bst
- gnome-build-meta.bst:sdk/adwaita-icon-theme.bst

depends:
- core-deps/gexiv2.bst
- core-deps/gnome-autoar.bst
- core-deps/libcloudproviders.bst
# Build dep of tests, and runtime dep otherwise
- core-deps/localsearch.bst
- core/gnome-desktop.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gsettings-desktop-schemas.bst
- gnome-build-meta.bst:sdk/gtk.bst
- gnome-build-meta.bst:sdk/libadwaita.bst
- gnome-build-meta.bst:sdk/libglycin-gtk4.bst
- gnome-build-meta.bst:sdk/libportal.bst
- gnome-build-meta.bst:sdk/pango.bst
- gnome-build-meta.bst:sdk/tinysparql.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  meson-local: >-
    -Dselinux=false
