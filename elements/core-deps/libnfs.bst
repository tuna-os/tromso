kind: autotools

sources:
- kind: git_repo
  url: github:sahlberg/libnfs.git
  track: '*.*'
  ref: libnfs-6.0.2-0-g18c5c73ee88bb7dc8da0d55dc95164bb77e49dc6

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- sdk/gssproxy.bst

variables:
  # libnfs 6.0.2 does not build with the C23 toolchain of freedesktop-sdk 26.08
  # (-Werror=discarded-qualifiers in libnfs.c and nfs_v3.c).
  conf-local: --disable-werror
