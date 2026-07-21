kind: cmake
description: CryFS encrypted filesystem (FUSE-based)

sources:
- kind: tar
  url: github:cryfs/cryfs/archive/refs/tags/1.0.3.tar.gz
  ref: 6742551505cc6b6b387279353627a27a93a3461b34284ba94666c365ad6cfcfd

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/python3.bst
- kde-linux-deps/fuse2.bst
- kde/libs/boost.bst
- kde-linux-deps/spdlog.bst
- kde-linux-deps/range-v3.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-linux-deps/fuse2.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/curl.bst
- kde/libs/boost.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DCRYFS_UPDATE_CHECKS=OFF

config:
  configure-commands:
    (<):
    - |
      # versioneer needs git history; replace getversion.py with a fixed version script
      cat > src/gitversion/getversion.py << 'EOF'
      #!/usr/bin/env python3
      print("1.0.3")
      EOF
