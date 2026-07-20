kind: autotools
description: PAM module for U2F/FIDO2 two-factor authentication (Yubico)

sources:
- kind: git_repo
  url: github:Yubico/pam-u2f.git
  track: pam_u2f-1.4.0
  ref: 1d85db26b590c191a508d06eddc86fbff6b5009e

variables:
  autogen: |
    echo "1.4.0" > .tarball-version
    autoreconf -ivf

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/linux-pam.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/libfido2.bst
- freedesktop-sdk.bst:components/asciidoc.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/linux-pam.bst
- freedesktop-sdk.bst:components/libfido2.bst

config:
  install-commands:
    (>):
    - |
      # usrmerge: /lib → /usr/lib (autotools installs PAM module to /lib/<arch>/security)
      if [ -d "%{install-root}/lib" ] && [ ! -L "%{install-root}/lib" ]; then
        cp -a "%{install-root}/lib/." "%{install-root}/usr/lib/"
        rm -rf "%{install-root}/lib"
      fi
