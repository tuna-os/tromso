kind: compose

build-depends:
- oci/kde-linux-system/stack.bst
- oci/kde-linux-system/manifest.bst

config:
  exclude:
  - debug
  - devel
  - doc
  - extra
  - static-blocklist
