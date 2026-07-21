kind: compose
description: Aurora final layer

build-depends:
  - freedesktop-sdk.bst:components/gcc.bst
  - oci/layers/tromso-runtime.bst

config:
  exclude:
    - debug
    - extra
    - static-blocklist
