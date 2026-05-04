kind: stack
description: Aurora-specific additions over KDE Linux base (mirrors dakota/elements/bluefin/deps.bst)

depends:
  # KDE Linux base provides Plasma, Frameworks, Qt6, Apps, kernel, systemd, bootc,
  # pipewire, networkmanager, polkit, mesa, podman, skopeo, sshd, etc.
  # Only list what Aurora adds *on top* of the base image here.

  # dosfstools: mkfs.fat required by bootc install to-disk for EFI partition
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dosfstools.bst

  # dconf: needed by dconf-update.service and KDE/GNOME settings infrastructure
  - kde-build-meta.bst:core-deps/dconf.bst

  # System configuration: dbus units, system users, sshd, networkd DHCP
  - aurora/system-config.bst

  # containers policy.json: required by bootc at runtime to accept images
  # (containers-common puts this in 'sysconf' split which aurora-runtime excludes)
  - aurora/containers-config.bst

  # Qt6 libraries install to /usr/lib, so add a runtime ld.so.conf.d drop-in
  # to make them visible to SDDM and other dynamically linked Qt binaries.
  - aurora/ldconfig-paths.bst

  # Upstream layer parity:
  # Bluefin common shared payload -> Aurora common -> Brew -> Aurora image overlay.
  - aurora/bluefin-common.bst

  # Aurora common/theme layer (sourced from get-aurora-dev/common + branding)
  - aurora/common.bst
  - aurora/logos.bst
  - aurora/wallpapers.bst
  - aurora/docs.bst
  - aurora/brew.bst
  - aurora/tailscale.bst
  - aurora/image-overlay.bst
  - aurora/multimedia-overrides.bst
  - aurora/fcitx5-cluster.bst

  # Fonts for SDDM and desktop text rendering. These were previously added in
  # 89d117f0a to fix tofu boxes in the graphical stack.
  - kde-build-meta.bst:gnomeos-deps/noto-fonts.bst
  - kde-build-meta.bst:gnomeos-deps/noto-cjk.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dejavu-fonts.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/liberation-fonts.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/noto-emoji.bst
  - aurora/kde-linux-noto-fontconfig.bst

  # System infrastructure (hardware enablement)
  - aurora/hardware-enablement.bst

  # Developer tooling (Aurora ships these in addition to base)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/buildstream2.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/debuginfod.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/bpf.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/vmlinuxh.bst
  - kde-build-meta.bst:core/sysprof-app.bst
  - kde-build-meta.bst:gnomeos-deps/just.bst
  # Dakota uses sudo-rs to preserve the setuid sudo binary in the final image.
  - aurora/sudo-rs.bst
