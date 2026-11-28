kind: make
description: >-
  The kernel of the Open Gaming Collective, with the out-of-tree modules that
  Bazzite adds. It replaces components/linux.bst of freedesktop-sdk when the
  project option `flavor` is `ogc` (elements/freedesktop-sdk.bst).

# One element builds the kernel and the out-of-tree modules. A module must
# have a signature from a key that the kernel trusts, and the private key must
# not enter the BuildStream cache, because CI publishes that cache. So the key
# is made in the tmpfs of the sandbox, it signs all modules, and it is gone at
# the end of the build. A second element could not sign with it.
#
# docs/OGC.md has the sources, the checks of the signatures, and how to move
# the version.

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/cpio.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/bc.bst
- freedesktop-sdk.bst:components/findutils.bst
- freedesktop-sdk.bst:components/gzip.bst
- freedesktop-sdk.bst:components/kmod.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/grep.bst
- freedesktop-sdk.bst:components/openssl.bst
- freedesktop-sdk.bst:components/pahole.bst
- freedesktop-sdk.bst:components/patch.bst
- freedesktop-sdk.bst:components/perl.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/rsync.bst
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:components/rust-bindgen.bst
- freedesktop-sdk.bst:components/rust-src.bst
- freedesktop-sdk.bst:components/tar.bst
- freedesktop-sdk.bst:components/util-linux.bst
- freedesktop-sdk.bst:components/zstd.bst

variables:
  bootdir: /boot
  optimize-debug: false
  # A strip of a signed module removes the signature.
  strip-binaries: ''
  # Built after the kernel, in this order. Each name is a directory below
  # ogc-modules/ that holds a Kbuild file or a Makefile for kbuild.
  ogc-modules: >-
    ayaneo-leds ayaneo-platform evdi/module gcadapter_oc hid-fanatecff
    hid-hori hid-tminit hid-tmff2 kvmfr/module logitech-trueforce/mainline
    nct6687d new-lg4ff openrazer/driver sc0710 system76 system76-io
    t150/hid-t150 v4l2loopback vhba xonedo zenergy

environment:
  ARCH: '%{arch}'
  KBUILD_BUILD_TIMESTAMP: 'Thu Nov 10 15:00:00 UTC 2011'
  KBUILD_BUILD_USER: tromso
  KBUILD_BUILD_HOST: tromso

config:
  configure-commands:
  - patch -p1 -s <ogc/monolithic.patch

  - ogc/merge-config.sh prepare ogc

  - make -j1 olddefconfig

  - ogc/merge-config.sh check ogc

  # The kernel makes a key by itself only at certs/signing_key.pem, which is in
  # the build root. This path is in the tmpfs of the sandbox. Stop if it is not.
  - |
    test "$(stat -f -c %T /tmp)" = tmpfs
    umask 077
    mkdir -p /tmp/ogc-modsign
    cat >/tmp/ogc-modsign/x509.genkey <<'EOF'
    [ req ]
    default_bits = 4096
    distinguished_name = req_distinguished_name
    prompt = no
    string_mask = utf8only
    x509_extensions = myexts

    [ req_distinguished_name ]
    O = Tromso
    CN = Tromso OGC kernel build-time module key

    [ myexts ]
    basicConstraints=critical,CA:FALSE
    keyUsage=digitalSignature
    subjectKeyIdentifier=hash
    authorityKeyIdentifier=keyid
    EOF
    openssl req -new -nodes -utf8 -sha512 -days 36500 -batch -x509 \
      -config /tmp/ogc-modsign/x509.genkey -outform PEM \
      -out /tmp/ogc-modsign/signing_key.pem \
      -keyout /tmp/ogc-modsign/signing_key.pem

  install-commands:
  - |
    install -Dm644 "$(make -s image_name)" '%{install-root}%{bootdir}/vmlinuz'
    install -Dm644 System.map '%{install-root}%{bootdir}/System.map'
    install -Dm644 .config '%{install-root}%{bootdir}/config'
    make INSTALL_MOD_PATH='%{install-root}%{prefix}' INSTALL_MOD_STRIP=1 \
      DEPMOD=true modules_install
    rm -f '%{install-root}%{indep-libdir}'/modules/*/{build,source}

  # zenergy gives the energy counters of the CPU to each user (mode 0444).
  # That is the PLATYPUS side channel (CVE-2020-12912). Give them to root only.
  - |
    sed -i 's/return 0444;/return 0400;/' ogc-modules/zenergy/zenergy.c
    grep -q 'return 0400;' ogc-modules/zenergy/zenergy.c

  - |
    for module in %{ogc-modules}; do
      dir="${PWD}/ogc-modules/${module}"
      echo "== out-of-tree module: ${module}"
      make -C "${PWD}" M="${dir}" CONFIG_HID_LOGITECH_HIDPP_DEBUG= modules
      make -C "${PWD}" M="${dir}" INSTALL_MOD_PATH='%{install-root}%{prefix}' \
        INSTALL_MOD_DIR=extra INSTALL_MOD_STRIP=1 DEPMOD=true modules_install
    done

  - |
    release=$(make -s kernelrelease)
    depmod -b '%{install-root}%{prefix}' -F System.map "${release}"

  # Every module must have a signature, and the key must be gone.
  - |
    release=$(make -s kernelrelease)
    modules='%{install-root}%{indep-libdir}/modules'
    unsigned=$(find "${modules}" -name '*.ko.zst' | while read -r ko; do
      zstd -dcq "${ko}" | tail -c 28 | grep -qa 'Module signature appended' || echo "${ko}"
    done)
    if [ -n "${unsigned}" ]; then
      echo "modules with no signature:" >&2
      echo "${unsigned}" >&2
      exit 1
    fi
    test -z "$(find "${modules}" -name '*.ko')"
    rm -rf /tmp/ogc-modsign
    if grep -rlE 'BEGIN (RSA |EC )?PRIVATE KEY' '%{install-root}'; then
      echo "a private key is in the artifact" >&2
      exit 1
    fi

  - |
    %{install-extra}

  # udev rules and modprobe options of the modules, from their own sources.
  - |
    rules='%{install-root}%{indep-libdir}/udev/rules.d'
    install -Dm644 -t "${rules}" ogc-modules/hid-tmff2/udev/99-t-lcm.rules
    install -Dm644 -t "${rules}" ogc-modules/hid-hori/udev/99-hori-wheel.rules
    install -Dm644 -t "${rules}" ogc-modules/t150/files/etc/udev/rules.d/10-t150.rules
    install -Dm644 -t "${rules}" ogc-modules/logitech-trueforce/udev/70-logitech-trueforce.rules
    install -Dm644 -t "${rules}" ogc-modules/logitech-trueforce/udev/71-logi-ffb-uhid.rules
    install -Dm644 ogc-modules/hid-fanatecff/fanatec.rules "${rules}/99-fanatec.rules"
    install -Dm644 ogc-modules/xonedo/install/modprobe.conf \
      '%{install-root}%{indep-libdir}/modprobe.d/xone.conf'

public:
  bst:
    split-rules:
      devel:
        (>):
        - '%{bootdir}/System.map'
    overlap-whitelist:
    - "%{project_licensedir}"
    - "%{project_licensedir}/**"
  cpe:
    vendor: linux
    product: linux_kernel
    version: '7.3.5'

sources:
# kernel.org. The signature of the tarball is from
# 647F28654894E3BD457199BE38DBBDC86092693E.
- kind: tar
  url: tar_https:cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.3.5.tar.xz
  ref: 8f293f83d54f0b7b9be56863ebc5e4ea79d73e530b4ae55c572be97ef39f0990
# Tag v7.3.5-ogc3, commit 7522e30f51f9197673eb7f771a6b841673c5af36. The
# detached signature of the patch is from
# 5D14C1B29026A9366B2EB4322B440F6473435C1A (Open Gaming Collective).
- kind: remote
  url: github_files:OpenGamingCollective/linux/releases/download/v7.3.5-ogc3/monolithic.patch
  ref: 53a70c95b5ec5580c3780df6c03cfba732ece16cdd2e3aadd76d55d7c5f79650
  directory: ogc
- kind: local
  path: files/ogc/kernel
  directory: ogc
# The commits are those of the Terra packages that Bazzite installs
# (terrapkg/packages 054ef9bcfbdca65444744ff70b30fa7ef4ecf193), or the HEAD of
# 2026-11-25 for the modules that Bazzite takes from COPR.
- kind: git_repo
  url: github:TiPSilva/ayaneo-leds.git
  ref: 0be120d0d580363f386a9e51ebf0370d6367f45c
  directory: ogc-modules/ayaneo-leds
- kind: git_repo
  url: github:ShadowBlip/ayaneo-platform.git
  # v0.3.5
  ref: eb849d5deabe70fde004f67349fa281af322a499
  directory: ogc-modules/ayaneo-platform
- kind: git_repo
  url: github:DisplayLink/evdi.git
  ref: 51748043f3f884a9eff38f11a7cf90daaa3de755
  directory: ogc-modules/evdi
- kind: git_repo
  url: github:HannesMann/gcadapter-oc-kmod.git
  ref: 0a7d7027d0dc5c0701b5c6f8664dfcb020e4a1cf
  directory: ogc-modules/gcadapter_oc
- kind: git_repo
  url: github:gotzl/hid-fanatecff.git
  ref: 13340fc8af6fa9e005469d6a801e7ddb246425b2
  directory: ogc-modules/hid-fanatecff
- kind: git_repo
  url: github:LinuxGamesTV/hori_control_systems.git
  # 0.0.8
  ref: 8f6e103995240a3d28016dc0b5d6240d6afa7794
  directory: ogc-modules/hid-hori
- kind: git_repo
  url: github:Kimplul/hid-tmff2.git
  ref: 7a1274d25b2304deed326c5a43bf3617fedcb990
  directory: ogc-modules/hid-tmff2
- kind: git_repo
  url: github:Kimplul/hid-tminit.git
  # the submodule commit of hid-tmff2
  ref: 8c4547288a6c182ed4ff131e36f710f11a76c4a9
  directory: ogc-modules/hid-tminit
- kind: git_repo
  url: github:gnif/LookingGlass.git
  ref: 1b485305d9267207701d01adbe7907e90bfd6990
  directory: ogc-modules/kvmfr
- kind: git_repo
  url: github:mescon/logitech-trueforce-linux-driver.git
  # v0.43.3
  ref: 4c8b7cce266eaf08455da5b0c7ab498c8a544979
  directory: ogc-modules/logitech-trueforce
- kind: git_repo
  url: github:Fred78290/nct6687d.git
  ref: 3e4861052c5d7931e66b6cb6a6484e733ff8a419
  directory: ogc-modules/nct6687d
- kind: git_repo
  url: github:berarma/new-lg4ff.git
  ref: 2092db19f7b40854e0427a1b2e39eda9f8d0c3cd
  directory: ogc-modules/new-lg4ff
- kind: git_repo
  url: github:openrazer/openrazer.git
  # v3.12.4
  ref: 1ef8a91712906a89fd332a2ed62bbd105315d6d1
  directory: ogc-modules/openrazer
- kind: git_repo
  url: github:Nakildias/sc0710.git
  ref: 60753c530e26aa5b616d507b8f90872c1bca2870
  directory: ogc-modules/sc0710
- kind: git_repo
  url: github:pop-os/system76-dkms.git
  ref: 90ea5e69af3bbc64ad373c7b8fec8c1197e8bd4f
  directory: ogc-modules/system76
- kind: git_repo
  url: github:pop-os/system76-io-dkms.git
  ref: fc71f154ab8d9810f960ba171479c68c44737649
  directory: ogc-modules/system76-io
- kind: git_repo
  url: github:scarburato/t150_driver.git
  ref: f7ecb30c65ee5f7870e921bc0a2354df8e1e8100
  directory: ogc-modules/t150
- kind: git_repo
  url: github:v4l2loopback/v4l2loopback.git
  # v0.15.4
  ref: 0f9ee86760b7f2bea174b7e3e7a1d38845da0ab4
  directory: ogc-modules/v4l2loopback
- kind: git_repo
  url: github:OpenGamingCollective/xonedo.git
  ref: 982cbcb019ae4d2bee5ae69385223409ee555c88
  directory: ogc-modules/xonedo
- kind: git_repo
  url: github:BoukeHaarsma23/zenergy.git
  ref: 2a40d24d9253298b3b7a7098e07895e72fef291c
  directory: ogc-modules/zenergy
- kind: tar
  url: sourceforge:cdemu/vhba-module-20260313.tar.xz
  ref: 293003bf5d9dc2b386db0d05f595c5548355a535d6dfc06fd379fd98bb190174
  directory: ogc-modules/vhba
