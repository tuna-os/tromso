kind: manual
description: small test element
build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
sources:
- kind: local
  path: files/test.txt
variables:
  # Disable stripper to avoid exitcode 127
  strip-binaries: "true"
config:
  build-commands:
  - touch /tmp/built
