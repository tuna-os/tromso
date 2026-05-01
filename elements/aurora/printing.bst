kind: stack
description: Printing support packages for Aurora (print daemon, drivers, utilities)

depends:
  # Core printing infrastructure
  - kde-build-meta.bst:freedesktop-sdk.bst:components/cups.bst

  # HP printer support
  - kde-build-meta.bst:freedesktop-sdk.bst:components/hplip.bst

  # Generic printer driver database and generator
  - kde-build-meta.bst:freedesktop-sdk.bst:components/foomatic-db.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/foomatic-db-engine.bst

  # High-quality printer drivers (Canon, Epson, etc)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/gutenprint.bst

  # Printer configuration UI
  - kde-build-meta.bst:freedesktop-sdk.bst:components/system-config-printer.bst
