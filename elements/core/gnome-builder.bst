kind: meson

sources:
- kind: git_repo
  url: gnome:gnome-builder.git
  track: main
  ref: 50.0-2-gd20e6544768ece22ca21e0b25be8fd45e6eca6c2

build-depends:
- freedesktop-sdk.bst:components/desktop-file-utils.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

runtime-depends:
- gnome-build-meta.bst:sdk/adwaita-icon-theme.bst
- gnome-build-meta.bst:sdk/gjs.bst
- gnome-build-meta.bst:sdk/pygobject.bst
- gnome-build-meta.bst:sdk/vala.bst
- freedesktop-sdk.bst:components/flatpak-builder.bst

depends:
- core-deps/cmark.bst
- core-deps/editorconfig-core-c.bst
- core-deps/gom.bst
- core-deps/jsonrpc-glib.bst
- core-deps/libgit2-glib.bst
- core-deps/libpeas.bst
- core-deps/libspelling.bst
- core-deps/template-glib.bst
- core-deps/vte.bst
- core/d-spy.bst
- core/gvfs-daemon.bst
- core/sysprof-app.bst
- gnome-build-meta.bst:sdk-deps/libpanel.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gtk.bst
- gnome-build-meta.bst:sdk/gtksourceview.bst
- gnome-build-meta.bst:sdk/libadwaita.bst
- gnome-build-meta.bst:sdk/libdex.bst
- gnome-build-meta.bst:sdk/libportal.bst
- gnome-build-meta.bst:sdk/librsvg.bst
- gnome-build-meta.bst:sdk/libsoup.bst
- gnome-build-meta.bst:sdk/webkitgtk-6.0.bst
- freedesktop-sdk.bst:components/flatpak.bst
- freedesktop-sdk.bst:components/llvm.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  meson-local: >-
    -Dprofiling=true
