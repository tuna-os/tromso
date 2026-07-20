kind: autotools

sources:
- kind: tar
  url: github_files:xiph/libopusenc/archive/refs/tags/v0.3.tar.gz
  ref: 5637474cdf4ff693977fe74039049349fef7b65e3a94ad8bde51ecfcd1e94a8e
  base-dir: libopusenc-0.3

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:components/opus.bst

config:
  configure-commands:
  - |
    # GitHub tarball lacks package_version file and configure script
    # Pre-create package_version so AC_INIT picks up the correct version for the .pc file
    echo 'PACKAGE_VERSION=0.3' > package_version
    autoreconf -ivf
  - "%{configure}"
