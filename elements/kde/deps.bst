kind: stack
description: KDE Aurora OS dependencies

depends:
# Base OS stack from freedesktop-sdk
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/util-linux-full.bst
# linux.bst omitted: kernel modules come from kde-linux-system/initramfs/signed-modules.bst
# (which has linux.bst as a build-dep). Adding it here causes overlap errors.
- freedesktop-sdk.bst:components/wireless-regdb-bin.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/dracut.bst
# os-release removed: provided by oci/integration/os-release.bst
- freedesktop-sdk.bst:components/shadow.bst
- freedesktop-sdk.bst:components/tzdata.bst
- freedesktop-sdk.bst:components/iproute2.bst
- freedesktop-sdk.bst:components/udisks.bst
- freedesktop-sdk.bst:vm/base-filesystem.bst
- freedesktop-sdk.bst:vm/config/journald.bst
- freedesktop-sdk.bst:vm/config/networkd.bst
- freedesktop-sdk.bst:vm/config/resolved.bst
# useradd-default removed: provided by freedesktop-sdk.bst:vm/config/useradd-ostree.bst
- freedesktop-sdk.bst:vm/config/flathub.bst
- freedesktop-sdk.bst:components/usbutils.bst
- freedesktop-sdk.bst:components/hosts.bst
- freedesktop-sdk.bst:components/flatpak.bst
- freedesktop-sdk.bst:components/nsswitch-config-bootable.bst

# KDE Plasma Desktop
- kde/org.kde.plasma.desktop.bst
- kde/config/plasma.bst

# KDE Applications
- kde/org.kde.apps.bst

# KDE Qt-adjacent libraries
- kde/libs/qcoro.bst
- kde/libs/qtkeychain-qt6.bst
- kde/libs/poppler-qt6.bst

# bootc for image-based updates
- kde-linux-deps/bootc.bst

# Audio
- freedesktop-sdk.bst:components/pipewire-daemon.bst
- freedesktop-sdk.bst:components/wireplumber.bst
- kde-linux-deps/pipewire-jack.bst

# Network — provided by core-deps/NetworkManager.bst via plasma-nm/networkmanager-qt transitive deps
# (using freedesktop-sdk version here would cause a duplicate-file overlap)

# Security
- freedesktop-sdk.bst:vm/config/sudo.bst
- freedesktop-sdk.bst:components/polkit.bst

# Graphics
- freedesktop-sdk.bst:vm/mesa-default.bst
- freedesktop-sdk.bst:components/vulkan-icd-loader.bst
- freedesktop-sdk.bst:components/libheif.bst
- freedesktop-sdk.bst:components/libjxl.bst
- freedesktop-sdk.bst:components/libavif.bst

# Storage
- freedesktop-sdk.bst:components/btrfs-progs.bst

# Containers
- freedesktop-sdk.bst:components/podman.bst
- freedesktop-sdk.bst:components/skopeo.bst
- kde-linux-deps/distrobox.bst
- kde-linux-deps/toolbox.bst

# Networking tools
- freedesktop-sdk.bst:components/iproute2.bst
- freedesktop-sdk.bst:components/iputils.bst

# Firewall
- kde-linux-deps/nftables.bst
- kde-linux-deps/firewalld.bst
- kde-linux-deps/ufw.bst

# VPN plugins (NetworkManager)
- kde-linux-deps/NetworkManager-openvpn.bst
- kde-linux-deps/NetworkManager-openconnect.bst
- kde-linux-deps/NetworkManager-vpnc.bst
- kde-linux-deps/NetworkManager-l2tp.bst
- kde-linux-deps/NetworkManager-pptp.bst
- kde-linux-deps/NetworkManager-sstp.bst
- kde-linux-deps/NetworkManager-strongswan.bst

# Shell and text tools
- freedesktop-sdk.bst:components/bash-completion.bst
- freedesktop-sdk.bst:components/bash-config.bst
- freedesktop-sdk.bst:components/jq.bst
- freedesktop-sdk.bst:components/less.bst
- freedesktop-sdk.bst:components/nano.bst
- freedesktop-sdk.bst:components/vim.bst
- freedesktop-sdk.bst:components/man-db.bst
- freedesktop-sdk.bst:components/man-pages.bst
- freedesktop-sdk.bst:components/plocate.bst

# Git
- freedesktop-sdk.bst:components/git.bst
- freedesktop-sdk.bst:components/git-lfs.bst

# Firmware
- freedesktop-sdk.bst:components/linux-firmware.bst
- freedesktop-sdk.bst:components/sof-firmware.bst

# SSH
- freedesktop-sdk.bst:components/openssh-systemd.bst

# Sync
- freedesktop-sdk.bst:components/rsync.bst

# Hardware
- kde-linux-deps/android-udev-rules.bst
- kde-linux-deps/iio-sensor-proxy.bst
- kde-linux-deps/nvme-cli.bst
- kde-linux-deps/uinput.bst
- kde-linux-deps/switcheroo-control.bst
- kde-linux-deps/efibootmgr.bst
- freedesktop-sdk.bst:components/kmod.bst
- freedesktop-sdk.bst:components/tpm2-tss.bst
- freedesktop-sdk.bst:components/sbsigntools.bst
- freedesktop-sdk.bst:components/ccid.bst
- freedesktop-sdk.bst:components/libva.bst
- kde-linux-deps/powertop.bst
- kde-linux-deps/solaar.bst
- kde-linux-deps/ydotool.bst
- kde-linux-deps/libratbag.bst
- kde-linux-deps/steam-devices.bst
- kde-linux-deps/pam-u2f.bst
- kde-linux-deps/yubikey-manager.bst
- kde-linux-deps/acsccid.bst
- kde-linux-deps/usb-modeswitch.bst
- kde-linux-deps/usbmuxd.bst
- kde-linux-deps/udev-hid-bpf.bst
# Intel GPU media/video acceleration
- kde-linux-deps/libvpl.bst
- kde-linux-deps/vpl-gpu-rt.bst
# YubiKey full-disk encryption support
- kde-linux-deps/yubico-c.bst
- kde-linux-deps/yubico-c-client.bst
- kde-linux-deps/yubikey-personalization.bst
- kde-linux-deps/yubikey-full-disk-encryption.bst
# OpenRazer daemon (userspace; no DKMS kernel modules)
- kde-linux-deps/python-daemonize.bst
- kde-linux-deps/python-pyudev.bst
- kde-linux-deps/python-setproctitle.bst
- kde-linux-deps/openrazer-daemon.bst

# Filesystem support
# ntfs-3g omitted: modern kernels have ntfs3 built-in (5.15+)
- kde-linux-deps/btrfsmaintenance.bst
- freedesktop-sdk.bst:components/e2fsprogs.bst
- freedesktop-sdk.bst:components/dosfstools.bst
- freedesktop-sdk.bst:components/xfsprogs.bst
- freedesktop-sdk.bst:components/erofs-utils.bst
- freedesktop-sdk.bst:components/f2fs-tools.bst
- freedesktop-sdk.bst:components/lvm2.bst
- kde-linux-deps/udisks2-btrfs.bst

# Printing and scanning
- kde-linux-deps/sane-backends.bst
- kde-linux-deps/sane-airscan.bst
- kde-linux-deps/cups-browsed.bst
- kde-linux-deps/ipp-usb.bst
- kde-linux-deps/gutenprint.bst
- kde-linux-deps/hplip.bst

# VM support
- kde-linux-deps/virtiofsd.bst
- kde-linux-deps/swtpm.bst
- kde-linux-deps/spice-vdagent.bst
- freedesktop-sdk.bst:components/unzip.bst

# Network utilities
- kde-linux-deps/dnsmasq.bst
- kde-linux-deps/iw.bst
- kde-linux-deps/nss-mdns.bst

# Bluetooth (BlueDevil, KDE Plasma)
- freedesktop-sdk.bst:components/bluez.bst

# Wayland utilities
- kde-linux-deps/wl-clipboard.bst
- freedesktop-sdk.bst:components/xwayland.bst

# Realtime audio privileges
- kde-linux-deps/realtime-privileges.bst

# Zram swap
- kde-linux-deps/zram-generator.bst

# Console
- kde-linux-deps/kmscon.bst

# Shell
- kde-linux-deps/fish.bst
- kde-linux-deps/zsh.bst

# Zsh plugins
- kde-linux-deps/zsh-autosuggestions.bst
- kde-linux-deps/zsh-syntax-highlighting.bst
- kde-linux-deps/zsh-history-substring-search.bst
- kde-linux-deps/zsh-completions.bst

# Flathub
- kde-linux-deps/flathub-config.bst

# System config
- kde-linux-deps/journald-config.bst
- kde-linux-deps/nm-connectivity-config.bst
- kde-linux-deps/wpa-supplicant-config.bst

# Noise suppression
- kde-linux-deps/noise-suppression-for-voice.bst

# KDE Plasma extras
- kde/plasma/plasma-vault.bst

# Printing
- freedesktop-sdk.bst:components/cups-daemon.bst

# Network filesystems
- kde-linux-deps/nfs-utils.bst

# Power management (x86 Intel thermal daemon, tuned PPD proxy)
- kde-linux-deps/upower.bst
- kde-linux-deps/thermald.bst
- kde-linux-deps/tuned-ppd.bst

# CLI tools (KDE Linux parity)
- kde-linux-deps/lsof.bst
- kde-linux-deps/tree.bst
- kde-linux-deps/alsa-utils.bst
- kde-linux-deps/inotify-tools.bst
- kde-linux-deps/espeak-ng.bst
- kde-linux-deps/drm-info.bst
- kde-linux-deps/fastfetch.bst
- kde-linux-deps/lshw.bst
- kde-linux-deps/wireguard-tools.bst
- kde-linux-deps/udftools.bst
- kde-linux-deps/cpupower.bst

# VM guest integration
- kde-linux-deps/qemu-guest-agent.bst

# XDG portal backends
- kde-linux-deps/xdg-desktop-portal-gtk.bst

# Archive format support (Ark)
# arj disabled: needs 9 Arch security patches + custom build system, low priority
- kde-linux-deps/lzop.bst
- kde-linux-deps/lrzip.bst
- kde-linux-deps/unrar.bst

# Document conversion
- kde-linux-deps/catdoc.bst

# Backup tools
- kde-linux-deps/bup.bst

# Encrypted filesystems
- kde-linux-deps/encfs.bst
- kde-linux-deps/cryfs.bst
- kde-linux-deps/gocryptfs.bst

# Filesystem tools
- freedesktop-sdk.bst:components/exfat-progs.bst
- kde-linux-deps/fatresize.bst
- kde-linux-deps/quota-tools.bst

# Android tools (ADB/fastboot)
- kde-linux-deps/android-tools.bst

# Audio encoding/decoding
- kde-linux-deps/libopusenc.bst
- kde-linux-deps/opus-tools.bst

# Spell checking and location
- freedesktop-sdk.bst:components/hunspell.bst
- freedesktop-sdk.bst:components/geoclue.bst

# RAW image support (Gwenview/digiKam)
- kde-linux-deps/libraw.bst

# Image codecs (HDR/JPEG XR)
- kde-linux-deps/imath.bst
- kde-linux-deps/openexr.bst
- kde-linux-deps/jxrlib.bst

# OCR support (Tesseract)
- kde-linux-deps/leptonica.bst
- kde-linux-deps/tesseract-data-eng.bst
- kde-linux-deps/tesseract.bst

# Fonts
- kde-linux-deps/noto-fonts-emoji.bst

# Spell check dictionaries
- kde-linux-deps/hunspell-en_us.bst

# Desktop integration (system tray, app menus)
- kde-linux-deps/libdbusmenu-gtk3.bst
- kde-linux-deps/ayatana-ido.bst
- kde-linux-deps/libayatana-indicator.bst
- kde-linux-deps/appmenu-gtk-module.bst
- kde-linux-deps/libappindicator-gtk3.bst

# AppImage support
- kde-linux-deps/squashfuse.bst
- kde-linux-deps/libappimage.bst

# KDE developer tools
- kde/apps/gammaray.bst

(?):
- arch == "aarch64":
    depends:
      (>):
      - kde-linux-deps/deps-aarch64.bst
- arch == "x86_64":
    depends:
      (>):
      - kde-linux-deps/microcode.bst
      - freedesktop-sdk.bst:components/ovmf.bst
