kind: meson

sources:
- kind: tar
  url: gnome_downloads:evince/48/evince-48.1.tar.xz
  ref: 7d8b9a6fa3a05d3f5b9048859027688c73a788ff6e923bc3945126884943fa10

build-depends:
- gnome-build-meta.bst:sdk/gtk-doc.bst
- freedesktop-sdk.bst:components/desktop-file-utils.bst
- freedesktop-sdk.bst:components/itstool.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- core-deps/libgxps.bst
- core/nautilus.bst
- gnome-build-meta.bst:sdk/adwaita-icon-theme.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gtk+-3.bst
- gnome-build-meta.bst:core-deps/libhandy.bst
- gnome-build-meta.bst:sdk/libsecret.bst
- freedesktop-sdk.bst:components/poppler.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  meson-local: >-
    -Dcomics=disabled
    -Ddjvu=disabled
    -Ddvi=disabled
    -Dgspell=disabled
    -Dintrospection=true
    -Dpreviewer=false
    -Dthumbnailer=false
    -Dviewer=false
    -Dgtk_doc=false
    -Dnautilus=false
