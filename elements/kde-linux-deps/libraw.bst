kind: autotools

sources:
- kind: tar
  url: tar_https:www.libraw.org/data/LibRaw-0.21.3.tar.gz
  ref: dba34b7fc1143503942fa32ad9db43e94f714e62a4a856e91617f8f3e1e0aa5c

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:components/jpeg.bst
- freedesktop-sdk.bst:components/lcms.bst

variables:
  conf-local: --disable-static --disable-jasper --disable-openmp
