kind: compose

build-depends:
- kde-linux-system/snapd/deps.bst
- kde-linux-system/snapd/manifest.bst

config:
  exclude:
  - debug
  - devel
  - doc
