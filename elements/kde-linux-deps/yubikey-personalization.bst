kind: autotools
description: YubiKey Personalization Tool (ykpers) - configure and manage YubiKey tokens

sources:
- kind: tar
  url: tar_https:developers.yubico.com/yubikey-personalization/Releases/ykpers-1.20.0.tar.gz
  ref: 0ec84d0ea862f45a7d85a1a3afe5e60b8da42df211bb7d27a50f486e31a79b93

variables:
  conf-local: "CFLAGS=\"${CFLAGS} -DTRUE=1 -DFALSE=0 -fcommon\""

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/json-c.bst
- kde-linux-deps/yubico-c.bst
- kde-linux-deps/yubico-c-client.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/json-c.bst
- kde-linux-deps/yubico-c.bst
- kde-linux-deps/yubico-c-client.bst
