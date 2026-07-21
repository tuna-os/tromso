kind: autotools
description: High-quality printer drivers for CUPS (Gutenprint 5.3.4)

sources:
- kind: tar
  url: tar_https:deb.debian.org/debian/pool/main/g/gutenprint/gutenprint_5.3.4.20220624T01008808d602.orig.tar.xz
  ref: ef514d4ca567b5871cfe7697127bee2c14d5d71d7fbc68d8fee96b0faaed90e7

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/cups-daemon.bst

depends:
- freedesktop-sdk.bst:components/cups-daemon.bst
- freedesktop-sdk.bst:components/libtiff.bst

variables:
  conf-local: >-
    --disable-static
    --disable-test
    --disable-samples
    --disable-escputil
    --without-gimp2
    --enable-cups-ppds
    --enable-translated-ppds

config:
  install-commands:
    (>):
    - |
      # cups/src Makefile hardcodes SBINDIR=/usr/sbin despite --sbindir configure flag
      if [ -d "%{install-root}/usr/sbin" ]; then
        find "%{install-root}/usr/sbin" -maxdepth 1 -not -type d \
          -exec mv {} "%{install-root}/usr/bin/" \;
        rmdir "%{install-root}/usr/sbin"
      fi
