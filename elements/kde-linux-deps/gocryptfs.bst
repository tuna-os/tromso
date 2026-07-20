kind: manual
description: Go-based FUSE encrypted filesystem

sources:
- kind: tar
  url: github:rfjakob/gocryptfs/archive/refs/tags/v2.6.1.tar.gz
  ref: 8b293c77703e9a45b629a47ce16aad701a9f2f53af5a8fb6200abe274f08051c
- kind: local
  path: files/gocryptfs/vendor.tar.gz

build-depends:
- freedesktop-sdk.bst:components/go.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/fuse3.bst
- freedesktop-sdk.bst:components/openssl.bst

environment:
  CGO_ENABLED: "1"

config:
  configure-commands:
  - python3 -c "import tarfile; tarfile.open('vendor.tar.gz').extractall()"

  build-commands:
  - go build -mod=vendor -v -o gocryptfs ./

  install-commands:
  - install -Dm755 gocryptfs "%{install-root}/usr/bin/gocryptfs"
