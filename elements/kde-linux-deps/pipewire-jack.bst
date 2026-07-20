kind: filter

build-depends:
- kde-linux-deps/pipewire-base-jack.bst

runtime-depends:
- freedesktop-sdk.bst:components/pipewire.bst

config:
  include:
  - jack
  include-orphans: False

public:
  bst:
    overlap-whitelist:
    - '/**'
