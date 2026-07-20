kind: autotools
description: StrongSwan IKEv2/IPsec VPN daemon with NetworkManager plugin support

sources:
- kind: tar
  url: tar_https:download.strongswan.org/strongswan-6.0.6.tar.bz2
  ref: 07df7cedae56a7f3bb07e66d21a1f9f87e961db70e99184e11d3819413e4f87c

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/NetworkManager.bst

depends:
- freedesktop-sdk.bst:components/gmp.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:components/linux-pam.bst
- freedesktop-sdk.bst:components/libcap.bst
- freedesktop-sdk.bst:components/sqlite.bst
- freedesktop-sdk.bst:components/systemd.bst

variables:
  conf-local: >-
    --sbindir=%{sbindir}
    --libexecdir=%{libdir}
    --with-ipsecdir=%{libdir}/strongswan
    --with-nm-ca-dir=/etc/ssl/certs
    --enable-openssl
    --enable-curl
    --enable-sqlite
    --enable-pkcs11
    --enable-eap-identity
    --enable-eap-md5
    --enable-eap-mschapv2
    --enable-eap-tls
    --enable-eap-ttls
    --enable-eap-peap
    --enable-eap-gtc
    --enable-eap-radius
    --enable-xauth-eap
    --enable-vici
    --enable-swanctl
    --enable-nm
    --without-libnm-glib
    --with-nm-ca-dir=/etc/ssl/certs
