kind: script
description: KDE Linux OCI image (full desktop + system)

build-depends:
- freedesktop-sdk.bst:components/fakecap.bst
- freedesktop-sdk.bst:components/oci-builder.bst
- freedesktop-sdk.bst:vm/prepare-image.bst
- oci/kde-linux/init-scripts.bst
- filename: freedesktop-sdk.bst:oci/platform-oci.bst
  config:
    location: /parent
- filename: oci/kde-linux/filesystem.bst
  config:
    location: /layer

environment:
  LD_PRELOAD: /usr/libexec/fakecap/fakecap.so
  FAKECAP_DB: /fakecap

variables:
  sysroot-seed: b57666f6-0fe5-4310-adff-f256936d164d

config:
  commands:
  - mkdir /fakecap
  # Clean up /lib/modules entirely - depmod will rebuild what it needs
  - |
    rm -rf /layer/lib/modules
    mkdir -p /layer/lib/modules
  - |
    prepare-image.sh \
       --sysroot /layer \
       --initscripts /initial_scripts \
       --seed "%{sysroot-seed}" \
       --noroot --noboot >/dev/null

  - |
    systemd-sysusers --root /layer

  - |
    cd "%{install-root}"
    build-oci <<EOF
    mode: oci
    gzip: disabled
    images:
    - os: linux
      architecture: "%{go-arch}"
      parent:
        image: /parent
      layer: /layer
      comment: "KDE Linux OCI image (full desktop + system)"
      config:
        Labels:
          'com.github.containers.toolbox': 'true'
          'org.opencontainers.image.source': 'https://github.com/hanthor/kde-build-meta/'
          'org.opencontainers.image.url': 'https://github.com/hanthor/kde-build-meta/'
          'containers.bootc': '1'
      index-annotations:
        'org.opencontainers.image.ref.name': 'ghcr.io/hanthor/kde-build-meta:kde-linux-%{branch}'
    EOF
