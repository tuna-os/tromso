kind: autotools
description: Yubico C library (libyubikey) - low-level YubiKey OTP support

sources:
- kind: tar
  url: tar_https:developers.yubico.com/yubico-c/Releases/libyubikey-1.13.tar.gz
  ref: 04edd0eb09cb665a05d808c58e1985f25bb7c5254d2849f36a0658ffc51c3401

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
