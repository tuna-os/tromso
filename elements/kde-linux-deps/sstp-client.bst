kind: autotools
description: SSTP (Secure Socket Tunneling Protocol) client

sources:
- kind: tar
  url: gitlab_files:sstp-project/sstp-client/-/archive/1.0.20/sstp-client-1.0.20.tar.gz
  ref: 9150c96c61c71aa3fd0ac7c2b95f60cecb8bf761febb07e00e34794c47eac9fa

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- core-deps/ppp.bst

depends:
- freedesktop-sdk.bst:components/libevent.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: >-
    --localstatedir=/var
    --disable-static
