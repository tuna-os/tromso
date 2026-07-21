kind: manual
description: Aurora OS release information with bootc support

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    cat <<ID_EOF > os-release
    NAME="Aurora"
    ID=aurora
    ID_LIKE=fedora
    VERSION_ID="20260428"
    PRETTY_NAME="Aurora KDE Linux"
    ANSI_COLOR="0;34"
    HOME_URL="https://github.com/james/kde-linux"
    SUPPORT_URL="https://github.com/james/kde-linux/issues"
    BUG_REPORT_URL="https://github.com/james/kde-linux/issues"
    PRIVACY_POLICY_URL="https://github.com/james/kde-linux"
    OSTREE_VERSION='20260428'
    BOOTC_IMAGE=1
    VARIANT="KDE Plasma"
    VARIANT_ID=kde
    ID_EOF
    install -Dm644 -t "%{install-root}%{indep-libdir}" os-release
    install -Dm644 -t "%{install-root}%{sysconfdir}" os-release
