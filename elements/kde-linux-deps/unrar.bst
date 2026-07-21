kind: manual
description: RAR archive extraction tool (unrar)

sources:
- kind: tar
  url: tar_https:www.rarlab.com/rar/unrarsrc-7.1.3.tar.gz
  ref: f7edb6f55fb53611206781d9e56f2625ef4411a6b129768800196617d9df920a

build-depends:
- freedesktop-sdk.bst:components/gcc.bst
- freedesktop-sdk.bst:components/binutils.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  build-commands:
  - make

  install-commands:
  - install -Dm755 unrar "%{install-root}/usr/bin/unrar"
