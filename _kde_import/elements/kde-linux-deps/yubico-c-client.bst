kind: autotools
description: Yubico C client library (ykclient) for server-side validation

sources:
- kind: tar
  url: github_files:Yubico/yubico-c-client/archive/ykclient-2.15/yubico-c-client-2.15.tar.gz
  ref: 3863f4fc2f3320c59fcbf57862bba48bcb716fddb886840bb0dd8db14d5ab7f0

variables:
  autogen: autoreconf -ivf

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:components/help2man.bst
- kde-linux-deps/yubico-c.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/curl.bst
- kde-linux-deps/yubico-c.bst
