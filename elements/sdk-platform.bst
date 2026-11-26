# Process for adding components to SDK:
# https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/home#process-to-add-components-to-the-sdk
#
# Process for removing components from SDK:
# https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/home#process-to-remove-components-from-sdk
kind: stack
depends:
- gnome-build-meta.bst:sdk/adwaita-fonts.bst
- gnome-build-meta.bst:sdk/adwaita-icon-theme.bst
- gnome-build-meta.bst:sdk/at-spi2-core.bst
- gnome-build-meta.bst:sdk/blueprint-compiler.bst
- gnome-build-meta.bst:sdk/cairo.bst
- gnome-build-meta.bst:sdk/cantarell-fonts.bst
- gnome-build-meta.bst:sdk/enchant-2.bst
- gnome-build-meta.bst:sdk/fcitx5-gtk.bst
- gnome-build-meta.bst:sdk/gcab.bst
- sdk/gcr-3.bst
- gnome-build-meta.bst:sdk/gcr.bst
- gnome-build-meta.bst:sdk/gdk-pixbuf.bst
- gnome-build-meta.bst:sdk/gjs.bst
- gnome-build-meta.bst:sdk/glib-networking.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/glycin.bst
- gnome-build-meta.bst:sdk/gobject-introspection.bst
- gnome-build-meta.bst:sdk/graphene.bst
- gnome-build-meta.bst:sdk/gsettings-desktop-schemas.bst
- gnome-build-meta.bst:sdk/gssproxy.bst
- gnome-build-meta.bst:sdk/gst-plugin-gtk4.bst
- gnome-build-meta.bst:sdk/gtk+-3.bst
- gnome-build-meta.bst:sdk/gtk.bst
- gnome-build-meta.bst:sdk/gtksourceview.bst
- gnome-build-meta.bst:sdk/gvfs-client.bst
- gnome-build-meta.bst:sdk/json-glib.bst
- gnome-build-meta.bst:sdk/krb5.bst
- gnome-build-meta.bst:sdk/libadwaita.bst
- gnome-build-meta.bst:sdk/libdex.bst
- gnome-build-meta.bst:sdk/libgee.bst
- gnome-build-meta.bst:sdk/libglycin-gtk4.bst
- gnome-build-meta.bst:core-deps/libhandy.bst
- gnome-build-meta.bst:sdk/libibus.bst
- gnome-build-meta.bst:sdk/libmanette-0.2.bst
- gnome-build-meta.bst:sdk/libnotify.bst
- gnome-build-meta.bst:sdk/libportal.bst
- sdk/librice.bst
- gnome-build-meta.bst:sdk/librsvg.bst
- gnome-build-meta.bst:sdk/libsecret.bst
- gnome-build-meta.bst:sdk/libsoup.bst
- gnome-build-meta.bst:sdk/mozjs.bst
- gnome-build-meta.bst:sdk/nuspell.bst
- gnome-build-meta.bst:sdk/pango.bst
- gnome-build-meta.bst:sdk/pinentry.bst
- gnome-build-meta.bst:sdk/pygobject.bst
- gnome-build-meta.bst:sdk/tinysparql.bst
- gnome-build-meta.bst:sdk/webkit2gtk-4.1.bst
- gnome-build-meta.bst:sdk/webkitgtk-6.0.bst
- gnome-build-meta.bst:sdk/woff2.bst
- gnome-build-meta.bst:sdk/yelp-xsl.bst
- gnome-build-meta.bst:sdk/yelp.bst
- freedesktop-sdk.bst:platform.bst

(?):
- channel == "nightly":
    depends:
      (>):
      # Only for testing atm
      - gnome-build-meta.bst:sdk/xwayland-satellite.bst

      # WIP with no stable release planned yet
      - gnome-build-meta.bst:sdk/libmanette.bst
