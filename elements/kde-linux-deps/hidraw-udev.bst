kind: manual

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - |
    install -Dm644 -t '%{install-root}%{indep-libdir}/udev/rules.d' 70-gnomeos-hidraw.rules

  - |
    install -Dm644 -t '%{install-root}%{indep-libdir}/udev/hwdb.d' 80-solaar.hwdb

  - |
    %{install-extra}

sources:
- kind: local
  path: files/kde-linux-system/hidraw/70-gnomeos-hidraw.rules
- kind: local
  path: files/kde-linux-system/hidraw/80-solaar.hwdb
