kind: compose
description: Filesystem for KDE Linux OCI image

build-depends:
- oci/kde-linux/stack.bst
- oci/kde-linux/manifest.bst

config:
  exclude:
  - debug
  - devel
  - doc
  - extra
  - static-blocklist
