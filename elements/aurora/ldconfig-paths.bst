kind: script
description: Ensure runtime linker searches /usr/lib for Qt6 libraries

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  commands:
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/ld.so.conf.d/10-usr-lib.conf" <<'EOF'
    /usr/lib
    /usr/lib64
    EOF

public:
  bst:
    split-rules:
      runtime:
        (>):
        - '%{sysconfdir}/ld.so.conf.d/10-usr-lib.conf'
