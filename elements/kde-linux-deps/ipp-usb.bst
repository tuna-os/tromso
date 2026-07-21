kind: make
description: IPP-over-USB daemon for driverless USB printing (ipp-usb 0.9.32)
# NOTE: This element requires Go module dependencies to be available offline.
# The build may fail in a network-isolated sandbox unless a vendor/ directory is
# bundled. Follow the toolbox.bst pattern: run `go mod vendor` and create a
# vendored source archive, then switch the source kind to tar pointing to it.

sources:
- kind: git_repo
  url: github:OpenPrinting/ipp-usb.git
  track: '*.*.*'
  ref: 0.9.32-0-g70359cff1e1e1ed110aea9adc0a9ef1c13638776

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/go.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/gzip.bst

depends:
- freedesktop-sdk.bst:components/avahi-libs.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  optimize-debug: "false"

environment:
  GOFLAGS: -mod=mod
  GOPATH: "%{build-root}/gopath"

config:
  build-commands:
  - make

  install-commands:
  - make DESTDIR="%{install-root}" install
  - |
    # usrmerge: /sbin → /usr/bin, /lib → /usr/lib
    if [ -d "%{install-root}/sbin" ]; then
      mkdir -p "%{install-root}/usr/bin"
      find "%{install-root}/sbin" -maxdepth 1 -not -type d \
        -exec mv {} "%{install-root}/usr/bin/" \;
      rmdir "%{install-root}/sbin"
    fi
    if [ -d "%{install-root}/lib" ] && [ ! -L "%{install-root}/lib" ]; then
      mkdir -p "%{install-root}/usr/lib"
      cp -a "%{install-root}/lib/." "%{install-root}/usr/lib/"
      rm -rf "%{install-root}/lib"
    fi
