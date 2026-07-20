kind: meson
description: Small utility to dump info about DRM devices

sources:
- kind: tar
  url: github:ascent12/drm_info/archive/refs/tags/v2.3.0.tar.gz
  ref: cb7e060f8f3e444cfbeb56480ad991ab13cc13bf43af6fbff576ffa54746500c

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- freedesktop-sdk.bst:components/json-c.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/pciutils.bst
