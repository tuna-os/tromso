kind: autotools
description: NetworkManager VPN plugin for PPTP

sources:
- kind: tar
  url: gnome_downloads:NetworkManager-pptp/1.2/NetworkManager-pptp-1.2.12.tar.xz
  ref: e5fa59fe46117f0ee86e9ca62c6943bc063884b04dd2396ccec38a2d1f414982

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/intltool.bst
- freedesktop-sdk.bst:components/systemd.bst

depends:
- sdk/gtk.bst
- sdk/libsecret.bst
- core-deps/libnma.bst
- core-deps/NetworkManager.bst
- core-deps/ppp.bst

variables:
  conf-local: >-
    --without-libnm-glib
    --with-gtk4
