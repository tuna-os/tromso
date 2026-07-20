kind: autotools
description: Daemon for automatic network printer discovery (cups-browsed 2.1.1)

sources:
- kind: tar
  url: tar_https:github.com/OpenPrinting/cups-browsed/releases/download/2.1.1/cups-browsed-2.1.1.tar.xz
  ref: d185169a74e6a5731b6bd74cba8d269f34e5c71cb71ef1841f2fa91637ba1d58

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:components/cups-daemon.bst
- freedesktop-sdk.bst:components/libppd.bst
- freedesktop-sdk.bst:components/libcupsfilters.bst
- freedesktop-sdk.bst:components/avahi.bst
- freedesktop-sdk.bst:components/avahi-libs.bst
- freedesktop-sdk.bst:components/dbus.bst

variables:
  conf-local: >-
    --disable-static
    --with-browseremoteprotocols=DNSSD,CUPS
