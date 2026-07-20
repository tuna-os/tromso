kind: autotools
description: Filesystem quota tools

sources:
- kind: tar
  url: tar_https:downloads.sourceforge.net/project/linuxquota/quota-tools/4.09/quota-4.09.tar.gz
  ref: 9cdaca154bc92afc3117f0e5f5b3208dd5f84583af1cf061c39baa0a2bb142f9

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/e2fsprogs.bst
- freedesktop-sdk.bst:components/libnl.bst
- freedesktop-sdk.bst:components/libdbus.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/e2fsprogs.bst
- freedesktop-sdk.bst:components/libnl.bst

variables:
  conf-local: >-
    --disable-ldap
    --disable-rpc
    --enable-ext2direct
    --enable-netlink
