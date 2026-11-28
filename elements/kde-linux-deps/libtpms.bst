kind: autotools

sources:
- kind: git_repo
  url: github:stefanberger/libtpms.git
  track: 'v*'
  ref: v0.10.2-0-g03ff2481e133540be3b3ffe3daa1483d2a73d967

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- sdk/json-glib.bst
- freedesktop-sdk.bst:components/gnutls.bst
- freedesktop-sdk.bst:components/iproute2.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/tpm2-tss.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  # libtpms 0.10.2 does not build with the C23 toolchain of freedesktop-sdk
  # 26.08 (tpm_library.c: -Werror=discarded-qualifiers).
  conf-local: >-
    CFLAGS="${CFLAGS} -Wno-error=discarded-qualifiers"
