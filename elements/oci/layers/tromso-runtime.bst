kind: compose
description: Tromso unified boot runtime

build-depends:
  - oci/layers/tromso-stack.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
