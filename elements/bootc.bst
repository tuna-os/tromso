kind: import
description: bootc binary (pre-built from local cache)

# Local tar source avoids all DNS/network issues in nested sandboxes
sources:
  - kind: local
    path: files/bootc-src/bootc.tar.gz
