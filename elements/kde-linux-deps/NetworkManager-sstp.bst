kind: autotools
description: NetworkManager VPN plugin for SSTP (Secure Socket Tunneling Protocol)

sources:
- kind: tar
  url: gnome_downloads:NetworkManager-sstp/1.3/NetworkManager-sstp-1.3.2.tar.xz
  ref: cddfa0f3a7192f289b2e160b6a5e97cd46fdc05bbb90744ea742b344cf794278

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/intltool.bst
- kde-linux-deps/sstp-client.bst

depends:
- kde-linux-deps/sstp-client.bst
- sdk/gtk.bst
- sdk/libsecret.bst
- core-deps/libnma.bst
- core-deps/NetworkManager.bst
- core-deps/ppp.bst
- freedesktop-sdk.bst:components/openssl.bst

variables:
  conf-local: >-
    --without-libnm-glib
    --with-gtk4
