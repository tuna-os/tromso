kind: autotools

sources:
- kind: git_repo
  url: github:linux-nfs/nfs-utils.git
  track: 'nfs-utils-*'
  ref: nfs-utils-2-9-1-0-gdebb85056805072a47fe8d167e3d6719d32c4d7b

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/libxml2.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libxml2.bst
- freedesktop-sdk.bst:components/libtirpc.bst
- freedesktop-sdk.bst:components/keyutils.bst
- freedesktop-sdk.bst:components/libevent.bst
- freedesktop-sdk.bst:components/libcap-ng.bst
- freedesktop-sdk.bst:components/sqlite.bst
- freedesktop-sdk.bst:components/libnl.bst
- freedesktop-sdk.bst:components/util-linux-full.bst

variables:
  conf-local: >-
    --disable-gss
    --disable-kprefix
    --without-tcp-wrappers
    --enable-ipv6
    --enable-nfsv4
    --enable-tirpc
    --disable-nfsv4l
    --disable-nfsdcld
    --disable-nfsdcltrack
    --without-ldap
    --with-rpcgen=internal

config:
  install-commands:
    (>):
    - |
      if [ -d "%{install-root}/sbin" ]; then
        mkdir -p "%{install-root}/usr/bin"
        find "%{install-root}/sbin" -maxdepth 1 -not -type d -exec mv {} "%{install-root}/usr/bin/" \;
        rm -rf "%{install-root}/sbin"
      fi
