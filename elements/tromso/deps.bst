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

  # accountsservice: required by SDDM to list users and manage user sessions
  - kde-build-meta.bst:core-deps/accountsservice.bst

  # System configuration: dbus units, system users, sshd, networkd DHCP
  - tromso/system-config.bst

  # containers policy.json: required by bootc at runtime to accept images
  # (containers-common puts this in 'sysconf' split which aurora-runtime excludes)
  - tromso/containers-config.bst

  # Qt6 libraries install to /usr/lib, so add a runtime ld.so.conf.d drop-in
  # to make them visible to SDDM and other dynamically linked Qt binaries.
  - tromso/ldconfig-paths.bst

  # Upstream layer parity:
  # Bluefin common shared payload -> Aurora common -> Brew -> Aurora image overlay.
  - tromso/bluefin-common.bst

  # Aurora common/theme layer (sourced from get-aurora-dev/common + branding)
  - tromso/common.bst
  - tromso/logos.bst
  - tromso/wallpapers.bst
  - tromso/docs.bst
  - tromso/brew.bst
  - tromso/tailscale.bst
  - tromso/image-overlay.bst
  - tromso/multimedia-overrides.bst
  - tromso/fcitx5-cluster.bst

  # Fonts for SDDM and desktop text rendering. These were previously added in
  # 89d117f0a to fix tofu boxes in the graphical stack.
  - kde-build-meta.bst:kde-linux-deps/noto-fonts.bst
  - kde-build-meta.bst:kde-linux-deps/noto-cjk.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dejavu-fonts.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/liberation-fonts.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/noto-emoji.bst
  - tromso/kde-linux-noto-fontconfig.bst

  # System infrastructure (hardware enablement)
  - tromso/hardware-enablement.bst

  # Boot splash: plymouth (auto-included in the initramfs by kde-build-meta's
  # 50-plymouth module once /usr/bin/plymouth exists) + KDE Linux breeze-bgrt
  # theme. Gives a branded splash and a graphical LUKS passphrase prompt.
  - kde-build-meta.bst:core-deps/plymouth.bst
  - tromso/plymouth-theme.bst

  # Developer tooling (Aurora ships these in addition to base)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/buildstream2.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/debuginfod.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/bpf.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/vmlinuxh.bst
  - kde-build-meta.bst:core/sysprof-app.bst
  - kde-build-meta.bst:kde-linux-deps/just.bst
  # Dakota uses sudo-rs to preserve the setuid sudo binary in the final image.
  - tromso/sudo-rs.bst

  # Aurora-specific KDE components
  - tromso/kcm_ublue.bst
  - tromso/krunner-bazaar.bst
