kind: autotools

sources:
- kind: git_repo
  url: freedesktop:xorg/driver/xf86-input-libinput.git
  track: 'xf86-input-libinput-*'
  ref: xf86-input-libinput-1.5.0-0-gc712930ef4b544a5036fe2f55fd2ade9efb8ea78

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/xorg-util-macros.bst
- core-deps/xorg-server-devel.bst

depends:
- freedesktop-sdk.bst:components/libinput.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
