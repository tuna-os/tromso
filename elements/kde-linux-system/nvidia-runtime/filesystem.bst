kind: compose

build-depends:
- kde-linux-system/nvidia-runtime/deps.bst
- kde-linux-system/nvidia-runtime/manifest.bst

config:
  exclude:
  - debug
  - devel
  - doc
