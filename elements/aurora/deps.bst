kind: stack
description: Aurora KDE Plasma desktop dependencies (matching Dakota structure)

depends:
  # Base freedesktop-sdk runtime
  - kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

  # Bootable system requirements (kernel + firmware for bootc)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/linux.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/linux-firmware.bst

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
  - kde-build-meta.bst:freedesktop-sdk.bst:components/openssh.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/podman.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/skopeo.bst

  # Performance tools
  - kde-build-meta.bst:freedesktop-sdk.bst:components/bpf.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/vmlinuxh.bst
  - kde-build-meta.bst:core/sysprof-app.bst

  # Desktop infrastructure & utilities (missing from KDE)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/xwayland.bst        # X11 on Wayland
  - kde-build-meta.bst:freedesktop-sdk.bst:components/less.bst            # Pager
  - kde-build-meta.bst:freedesktop-sdk.bst:components/util-linux.bst      # mount, fdisk, etc.
  - kde-build-meta.bst:freedesktop-sdk.bst:components/avahi.bst           # mDNS service discovery

  # Fonts (for proper text rendering)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dejavu-fonts.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/liberation-fonts.bst

  # bootc - container/image management (disabled due to Cargo/DNS build issues)
  # TODO: Resolve DNS/Cargo issues for bootc build (see feedback_bootc_dns.md)
  # - kde-build-meta.bst:gnomeos-deps/bootc.bst

  # TODO: Add systemsettings back after fixing plasma-activities dependency order
