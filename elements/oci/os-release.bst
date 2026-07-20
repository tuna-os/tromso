kind: manual
description: Aurora OS release information

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

environment:
  IMAGE_NAME: "aurora"
  IMAGE_VENDOR: "tuna-os"
  IMAGE_REF: "ostree-image-signed:docker://ghcr.io/tuna-os/tromso"
  IMAGE_FLAVOR: "main"
  IMAGE_TAG: "latest"
  VERSION_ID: "0"
  IMAGE_VERSION: "0"
  IMAGE_PRETTY_NAME: "Aurora Tromso"
  HOME_URL: "https://github.com/tuna-os/tromso"
  DOCUMENTATION_URL: "https://github.com/tuna-os/tromso"
  SUPPORT_URL: "https://github.com/tuna-os/tromso/issues"
  BUG_SUPPORT_URL: "https://github.com/tuna-os/tromso/issues"
  ID: "aurora"

config:
  build-commands:
    - mkdir -p %{install-root}%{indep-libdir}/
    - |
      cat >"%{install-root}%{indep-libdir}/os-release" <<EOF
      NAME="${IMAGE_PRETTY_NAME}"
      ID="${ID}"
      ID_LIKE="fedora"
      VERSION="${IMAGE_TAG}"
      PRETTY_NAME="${IMAGE_PRETTY_NAME}"
      BUG_REPORT_URL="${BUG_SUPPORT_URL}"
      HOME_URL="${HOME_URL}"
      DOCUMENTATION_URL="${DOCUMENTATION_URL}"
      SUPPORT_URL="${SUPPORT_URL}"
      LOGO=tromso
      ANSI_COLOR="0;34"
      DEFAULT_HOSTNAME="aurora"
      IMAGE_NAME="${IMAGE_NAME}"
      IMAGE_VENDOR="${IMAGE_VENDOR}"
      IMAGE_REF="${IMAGE_REF}"
      IMAGE_FLAVOR="${IMAGE_FLAVOR}"
      IMAGE_TAG="${IMAGE_TAG}"
      VERSION_ID="${VERSION_ID}"
      IMAGE_VERSION="${IMAGE_VERSION}"
      EOF
      mkdir -p %{install-root}%{sysconfdir}/
      ln -sf ../usr/lib/os-release %{install-root}%{sysconfdir}/os-release
