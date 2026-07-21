kind: make
description: CPU frequency and power management tools from linux-tools

sources:
- kind: tar
  url: tar_https:cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.85.tar.xz
  ref: e35ac999f40a6874493d8d60f33f1150d7a89ae5841c428da82257fbcd070aed

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/gettext.bst
- freedesktop-sdk.bst:components/pciutils.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  make-args: >-
    -C tools/power/cpupower
    DEBUG=false
    NLS=false
    CPUFREQ_BENCH=false
  make-install-args: >-
    -C tools/power/cpupower
    bindir="%{bindir}"
    libdir="%{libdir}"
    mandir="%{datadir}/man"
    CPUFREQ_BENCH=false
