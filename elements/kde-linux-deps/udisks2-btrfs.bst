kind: autotools
description: UDisks2 btrfs filesystem plugin
# NOTE: The freedesktop-sdk udisks element (components/udisks.bst) does NOT
# build the btrfs plugin because libbtrfsutil (from btrfs-progs) is not listed
# as a build dependency. This element rebuilds udisks from the same source with
# btrfs support enabled, installing only the btrfs plugin files.
#
# This requires that btrfs-progs (freedesktop-sdk.bst:components/btrfs-progs.bst)
# provides libbtrfsutil at build time. The udisks2 --enable-btrfs configure flag
# requires libbtrfsutil headers.
#
# If this causes overlap errors with components/udisks.bst, consider using a
# filter element or building udisks once with btrfs enabled.

sources:
- kind: git_repo
  url: github:storaged-project/udisks.git
  track: udisks-*
  exclude:
  - "udisks-2.10.90"
  - "udisks-2.10.91"
  ref: udisks-2.11.1-0-g6375ff14d3fed5f20c66ff50cfc02844473294a1

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- freedesktop-sdk.bst:components/gobject-introspection.bst
- freedesktop-sdk.bst:components/gtk-doc.bst
- freedesktop-sdk.bst:components/btrfs-progs.bst

depends:
- freedesktop-sdk.bst:components/libatasmart.bst
- freedesktop-sdk.bst:components/libblockdev.bst
- freedesktop-sdk.bst:components/libgudev.bst
- freedesktop-sdk.bst:components/polkit.bst
- freedesktop-sdk.bst:components/btrfs-progs.bst

variables:
  build-dir: ''
  conf-local: >-
    --enable-btrfs

config:
  install-commands:
  - |
    # Install only the btrfs plugin to avoid overlapping with udisks from FDO
    plugindir="%{install-root}%{libdir}/udisks2/modules"
    install -dm755 "${plugindir}"
    install -m755 modules/btrfs/.libs/libudisks2_btrfs.so "${plugindir}/"
