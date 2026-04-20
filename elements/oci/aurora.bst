kind: script
description: Aurora KDE Linux OCI image

build-depends:
  - kde-build-meta.bst:freedesktop-sdk.bst:components/fakecap.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/oci-builder.bst
  - freedesktop-sdk.bst:components/glib.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:vm/prepare-image.bst
  - filename: kde-build-meta.bst:oci/gnomeos/image.bst
    config:
      location: /parent
  - filename: oci/layers/aurora.bst
    config:
      location: /layer

environment:
  LD_PRELOAD: /usr/libexec/fakecap/fakecap.so
  FAKECAP_DB: /fakecap

variables:
  sysroot-seed: a1b2c3d4-e5f6-7890-abcd-ef1234567890

config:
  commands:
    - mkdir /fakecap
    - |
      prepare-image.sh \
         --sysroot /layer \
         --initscripts /initial_scripts \
         --seed "%{sysroot-seed}" \
         --noroot --noboot >/dev/null

    - |
      systemd-sysusers --root /layer

    - |
      glib-compile-schemas /layer/usr/share/glib-2.0/schemas

    # bootc images must not have both /etc and /usr/etc.
    - |
      if [ -d /layer/usr/etc ]; then
        mkdir -p /layer/etc
        cp -a /layer/usr/etc/. /layer/etc/
        rm -rf /layer/usr/etc
      fi

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
        comment: "Import Aurora layer"
        config:
          Labels:
            'com.github.containers.toolbox': 'true'
            'org.opencontainers.image.title': 'Aurora'
            'org.opencontainers.image.description': 'A KDE Plasma desktop image based on freedesktop-sdk'
            'org.opencontainers.image.vendor': 'Hanthor'
            'org.opencontainers.image.licenses': 'Apache-2.0'
            'org.opencontainers.image.url': 'https://github.com/hanthor/aurora-dakota'
            'org.opencontainers.image.source': 'https://github.com/hanthor/aurora-dakota'
            'containers.bootc': '1'
        index-annotations:
          'org.opencontainers.image.ref.name': 'ghcr.io/hanthor/aurora-dakota:latest'
      EOF
