kind: stack
description: Aurora KDE Plasma desktop dependencies (matching Dakota structure)

depends:
  # Base freedesktop-sdk runtime
  - kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

  # Bootable system requirements (kernel + firmware for bootc)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/linux.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/linux-firmware.bst

  # KDE Plasma desktop environment (graphical shell)
  # Note: Using direct plasma.service launch via systemd preset instead of SDDM
  # - kde-build-meta.bst:kde/plasma/sddm.bst          # TODO: Fix patch application issue
  - kde-build-meta.bst:kde/plasma/plasma-workspace.bst # Plasma workspace (X11 + Wayland support)
  - kde-build-meta.bst:kde/plasma/plasma-desktop.bst  # Desktop shell
  - kde-build-meta.bst:kde/plasma/kwin.bst            # Window manager (X11 enabled)
  - kde-build-meta.bst:kde/plasma/breeze.bst          # Default theme
  # - kde-build-meta.bst:kde/plasma/kscreen.bst         # Screen management (TODO: cmake config error)
  # - kde-build-meta.bst:kde/plasma/plasma-nm.bst       # Network Manager integration (TODO: complex deps)
  # - kde-build-meta.bst:kde/plasma/plasma-pa.bst       # PulseAudio integration (TODO: debug)
  # - kde-build-meta.bst:kde/plasma/konsole.bst         # Terminal application (TODO: D-Bus XML parsing)
  # - kde-build-meta.bst:kde/plasma/spectacle.bst       # Screenshot tool (TODO: debug)
  # - kde-build-meta.bst:kde/plasma/powerdevil.bst      # Power management (TODO: complex deps)
  # - kde-build-meta.bst:kde/plasma/plasma-systemmonitor.bst (TODO: cmake config)
  # - kde-build-meta.bst:kde/plasma/kinfocenter.bst (TODO: about-distro module)
  # - kde-build-meta.bst:kde/plasma/bluedevil.bst       # Bluetooth support (TODO: debug)
  # - kde-build-meta.bst:kde/plasma/xdg-desktop-portal-kde.bst (TODO: debug)
  - kde-build-meta.bst:kde/config/plasma.bst          # Systemd preset & service files

  # Qt6 components (required by various Plasma packages)
  - kde-build-meta.bst:kde/qt6/qt6-qtlocation.bst

  # KDE libraries needed by multiple Plasma packages
  - kde-build-meta.bst:kde/libs/qcoro.bst               # C++ coroutines for Qt
  - kde-build-meta.bst:kde/plasma/layer-shell-qt.bst    # Wayland layer shell
  - kde-build-meta.bst:kde/plasma/libplasma.bst         # Plasma library
  - kde-build-meta.bst:kde/plasma/libkscreen.bst        # Screen management lib
  - kde-build-meta.bst:kde/plasma/libksysguard.bst      # System monitor lib
  - kde-build-meta.bst:kde/plasma/kpipewire.bst         # PipeWire support
  - kde-build-meta.bst:kde/plasma/kwayland.bst          # Wayland support
  - kde-build-meta.bst:kde/plasma/kscreenlocker.bst     # Screen locker

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

  # bootc - container/image management (using Dakota's .bst file)
  # Built from source like Dakota does - provides bootc for image management
  # Network access now available via --network=host in Justfile
  - kde-build-meta.bst:gnomeos-deps/bootc.bst

  # TODO: Add systemsettings back after fixing plasma-activities dependency order
