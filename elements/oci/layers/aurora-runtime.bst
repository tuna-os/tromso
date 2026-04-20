kind: compose
description: Aurora runtime layer (without devel artifacts)

build-depends:
  - oci/layers/aurora-stack.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
