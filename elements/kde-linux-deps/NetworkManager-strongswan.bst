kind: autotools
description: NetworkManager plugin for StrongSwan IKEv2 VPN

sources:
- kind: tar
  url: tar_https:download.strongswan.org/NetworkManager/NetworkManager-strongswan-1.6.4.tar.bz2
  ref: 5fd7ed9e8a20c365bea7d653760a0409f9b212444006d4365332bbcc518f6c15

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/intltool.bst

depends:
- sdk/gtk.bst
- sdk/libsecret.bst
- core-deps/libnma.bst
- core-deps/NetworkManager.bst

runtime-depends:
- kde-linux-deps/strongswan.bst

variables:
  conf-local: >-
    --without-libnm-glib
    --with-gtk4
    --with-charon=/usr/lib/strongswan/charon-nm
  local_flags: -Wno-error=deprecated-declarations
