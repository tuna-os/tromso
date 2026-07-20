kind: manual
description: Explicit bootc configuration for Aurora

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - mkdir -p "%{install-root}%{indep-libdir}/bootc/install"
  - |
    cat <<BOOT_EOF > 00-aurora.conf
    [install]
    root-fs-type = btrfs
    BOOT_EOF
    install -Dm644 00-aurora.conf "%{install-root}%{indep-libdir}/bootc/install/00-aurora.conf"
  - |
    mkdir -p "%{install-root}%{indep-libdir}/ostree"
    cat <<'OSTREE_EOF' > prepare-root.conf
    [composefs]
    enabled = maybe

    [sysroot]
    readonly = true
    OSTREE_EOF
    install -Dm644 prepare-root.conf "%{install-root}%{indep-libdir}/ostree/prepare-root.conf"
