kind: compose
description: Tromso local Mkosi DDI root tree (not bootc-installed)

build-depends:
  - oci/layers/tromso-runtime.bst

config:
  include:
    - runtime
    - bootc
    - ostree-boot
  exclude:
    - debug
    - devel
    - doc
    - extra
    - static-blocklist
