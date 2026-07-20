kind: autotools
description: NetworkManager VPN plugin for L2TP/IPsec

sources:
- kind: tar
  url: github_files:nm-l2tp/NetworkManager-l2tp/releases/download/1.52.2/NetworkManager-l2tp-1.52.2.tar.xz
  ref: 05613dde2c285e88c46608e9f21c0a44c43d915f2d44bb38efd4128cdac5e9fc

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/ppp.bst
- freedesktop-sdk.bst:components/nss.bst

depends:
- sdk/gtk.bst
- sdk/libsecret.bst
- core-deps/libnma.bst
- core-deps/NetworkManager.bst
- core-deps/ppp.bst
- freedesktop-sdk.bst:components/openssl.bst

runtime-depends:
- kde-linux-deps/xl2tpd.bst

variables:
  conf-local: >-
    --without-libnm-glib
    --with-gtk4
