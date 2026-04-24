kind: stack
description: Aurora KDE Plasma desktop dependencies (matching Dakota structure)

depends:
  # Base freedesktop-sdk runtime
  - kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

  # KDE core applications (equivalent to Dakota's GNOME stack)
  - kde-build-meta.bst:kde/apps/dolphin.bst           # File manager (like nautilus)
  - kde-build-meta.bst:kde/apps/kate.bst              # Text editor
  - kde-build-meta.bst:kde/apps/okular.bst            # PDF viewer
  - kde-build-meta.bst:kde/apps/gwenview.bst          # Image viewer
  - kde-build-meta.bst:kde/apps/elisa.bst             # Music player
  - kde-build-meta.bst:kde/apps/ark.bst               # Archive manager
  - kde-build-meta.bst:kde/apps/kcalc.bst             # Calculator
  - kde-build-meta.bst:kde/apps/kdeconnect.bst        # Device connectivity

  # Developer tools (via gnome-build-meta for freedesktop-sdk components)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/buildstream2.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/containers-common.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/debuginfod.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/git-lfs.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/git.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/podman.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/skopeo.bst

  # Performance tools
  - kde-build-meta.bst:freedesktop-sdk.bst:components/bpf.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/vmlinuxh.bst
  - kde-build-meta.bst:core/sysprof-app.bst

  # TODO: Add systemsettings back after fixing plasma-activities dependency order
