kind: script

build-depends:
- filename: kde-linux-system/update-images-user-only.bst
  strict: true
  config:
    location: "%{install-root}"
- filename: kde-linux-system/devel/image.bst
  strict: true
  config:
    location: "%{install-root}"
- filename: kde-linux-system/snapd/image.bst
  strict: true
  config:
    location: "%{install-root}"
- filename: kde-linux-system/debug/image.bst
  strict: true
  config:
    location: "%{install-root}"
- filename: kde-linux-system/debug/layer-tar.bst
  config:
    location: "%{install-root}"
- filename: kde-linux-system/codecs-extra/image.bst
  config:
    location: "%{install-root}"
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

(?):
- arch in ["x86_64"]:
    build-depends:
      (>):
      - filename: kde-linux-system/nvidia-modules/image.bst
        strict: true
        config:
          location: "%{install-root}"
      - filename: kde-linux-system/nvidia-runtime/image.bst
        strict: true
        config:
          location: "%{install-root}"

config:
  commands:
  - |
    cd "%{install-root}"
    rm SHA256SUMS
    sha256sum * | tee SHA256SUMS
