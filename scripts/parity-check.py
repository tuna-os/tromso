#!/usr/bin/env python3
"""
parity-check.py — Compare KDE Linux mkosi packages against Aurora BuildStream elements.

Usage:
    python3 scripts/parity-check.py [--missing-only] [--csv] [--versions]
    python3 scripts/parity-check.py --extra

Output: table showing each KDE Linux package and whether Aurora provides it,
plus a summary of gaps.

With --versions: also shows the version in our BST element and the current
Arch Linux package version (fetched from archlinux.org; requires internet).

With --extra: reverse check — show gnomeos-deps BST elements that are NOT
in KDE Linux mkosi, so we can audit for packages that don't belong.
"""

import os
import re
import sys
import time
import argparse
import urllib.request
import urllib.error
import json
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
BST_ELEMENTS_DIR = REPO_ROOT / "kde-build-meta-local" / "elements"
MKOSI_CONF_DIR = Path("/tmp/kde-linux/mkosi.conf.d")

# ---------------------------------------------------------------------------
# Version extraction
# ---------------------------------------------------------------------------

def extract_bst_version(bst_path: Path) -> str | None:
    """
    Extract a human-readable version string from a .bst element file.
    Tries, in order:
      1. variables: version: X.Y.Z
      2. git_repo ref: vX.Y.Z-N-gabcdef  (tag-describe format, dots or dashes)
      3. tarball URL: package-X.Y.Z.tar.*
    """
    try:
        content = bst_path.read_text()
    except OSError:
        return None

    # 1. Explicit variable
    m = re.search(r"^\s*version:\s*[\"']?([0-9][^\s\"'\n]+)", content, re.MULTILINE)
    if m:
        return m.group(1)

    # 2. Git ref in tag-describe format: v1.2.3-0-gabcdef or pkg-1-2-3-0-gabcdef
    # Handle both dot-separated (v1.2.3) and dash-separated (nfs-utils-2-9-1) tag names.
    m = re.search(r"\bref:\s*[^0-9\n]*?([0-9][0-9._-]*[0-9])-\d+-g[0-9a-f]{7,}", content)
    if m:
        raw = m.group(1)
        # Normalise dash-separated version segments to dots: 2-9-1 → 2.9.1
        # But only if it looks like a version (all segments numeric)
        parts = raw.split("-")
        if all(p.isdigit() for p in parts):
            return ".".join(parts)
        # Mixed (e.g. 1.2.3-rc1) — leave as-is but strip leading dashes
        return raw.lstrip("-v")

    # 3. Tarball URL version: foo-1.2.3.tar or foo-1.2.3.zip
    m = re.search(r"url:.*?[-_]([0-9][0-9._]*[0-9a-z]*)\.(?:tar|zip|tgz)", content, re.IGNORECASE)
    if m:
        v = m.group(1)
        # Skip if it looks like a hash (all hex, long)
        if not (len(v) > 12 and all(c in "0123456789abcdef" for c in v)):
            return v

    return None


_arch_version_cache: dict[str, str | None] = {}

def fetch_arch_versions_bulk(packages: list[str]) -> dict[str, str | None]:
    """
    Fetch current Arch Linux package versions for a list of packages serially.
    Returns {pkgname: version_or_None}.
    """

    def _fetch_one(pkg: str) -> tuple[str, str | None]:
        if pkg in _arch_version_cache:
            return pkg, _arch_version_cache[pkg]
        url = f"https://archlinux.org/packages/search/json/?name={pkg}&arch=x86_64"
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "aurora-parity-check/1.0"})
            with urllib.request.urlopen(req, timeout=8) as resp:
                data = json.loads(resp.read())
            results = data.get("results", [])
            ver = results[0]["pkgver"] if results else None
        except Exception as e:
            print(f"\nWARN: fetch {pkg}: {e}", file=sys.stderr)
            ver = None
        _arch_version_cache[pkg] = ver
        return pkg, ver

    result: dict[str, str | None] = {}
    total = len(packages)
    for done, pkg in enumerate(packages, 1):
        _, ver = _fetch_one(pkg)
        result[pkg] = ver
        print(f"\r  Fetching Arch versions... {done}/{total}", end="", flush=True, file=sys.stderr)
        time.sleep(0.3)
    print(file=sys.stderr)
    return result


def find_bst_file_for_package(pkg: str, bst_elements: set[str]) -> Path | None:
    """
    Given a package name and the set of relative .bst paths, return the
    absolute Path to the most likely BST element for that package, or None.
    """
    # 1. Direct gnomeos-deps/<pkg>.bst
    candidate = f"gnomeos-deps/{pkg}.bst"
    if candidate in bst_elements:
        return BST_ELEMENTS_DIR / candidate

    # 2. Any element whose stem matches pkg (or stripped name)
    clean = re.sub(r"^(kf6-|plasma-|kde-|qt6-|python-)", "", pkg)
    for bst in bst_elements:
        stem = Path(bst).stem
        if stem in (pkg, clean):
            return BST_ELEMENTS_DIR / bst

    return None

# ---------------------------------------------------------------------------
# Manual mapping: KDE Linux package name → how Aurora covers it.
# Value is a short description; None means "not covered".
# This handles cases where names don't match automatically.
# ---------------------------------------------------------------------------
MANUAL_MAP = {
    # Firmware / microcode
    "amd-ucode":                  "gnomeos-deps/microcode.bst (combined with intel-ucode)",
    "intel-ucode":                "gnomeos-deps/intel-ucode.bst + microcode.bst",
    "linux-firmware":             "freedesktop-sdk.bst:components/linux-firmware.bst",
    "sof-firmware":               "freedesktop-sdk.bst:components/sof-firmware.bst",

    # Kernel / boot
    "linux-zen":                  "SKIP: kernel provided by freedesktop-sdk signed-modules",
    "linux-zen-headers":          "SKIP: kernel headers not needed (no DKMS in OCI image)",
    "kernel-modules-hook":        "SKIP: Arch-specific hook, not applicable",
    "shim":                       "gnomeos-deps/shim.bst (in gnome-build-meta, not wired in yet)",
    "systemd-ukify":              "SKIP: UKI generation handled by initramfs pipeline",
    "systemd-sysvcompat":         "SKIP: covered by freedesktop-sdk systemd",
    "systemd-resolvconf":         "SKIP: covered by freedesktop-sdk systemd/resolved",
    "plymouth":                   "SKIP: not yet integrated (future work)",
    "mkinitcpio":                 "SKIP: Arch-specific, initramfs via dracut",
    "mkinitcpio-systemd-tool":    "SKIP: Arch-specific",
    "pacman":                     "SKIP: Arch-specific package manager",
    "arch-install-scripts":       "SKIP: Arch-specific",

    # Base userland covered by FDO runtime-minimal
    "glibc-locales":              "SKIP: FDO runtime-minimal includes locales",
    "systemd":                    "freedesktop-sdk.bst:components/systemd.bst",
    "xdg-user-dirs":              "SKIP: provided by FDO/KDE Plasma integration",
    "glib-locales":               "SKIP: FDO runtime-minimal",

    # FDO-covered packages
    "flatpak":                    "freedesktop-sdk.bst:components/flatpak.bst",
    "iproute2":                   "freedesktop-sdk.bst:components/iproute2.bst",
    "less":                       "freedesktop-sdk.bst:components/less.bst",
    "nano":                       "freedesktop-sdk.bst:components/nano.bst",
    "vim":                        "freedesktop-sdk.bst:components/vim.bst",
    "git":                        "freedesktop-sdk.bst:components/git.bst",
    "git-lfs":                    "freedesktop-sdk.bst:components/git-lfs.bst",
    "jq":                         "freedesktop-sdk.bst:components/jq.bst",
    "podman":                     "freedesktop-sdk.bst:components/podman.bst",
    "usbutils":                   "freedesktop-sdk.bst:components/usbutils.bst",
    "unzip":                      "freedesktop-sdk.bst:components/unzip.bst",
    "rsync":                      "freedesktop-sdk.bst:components/rsync.bst",
    "openssh":                    "freedesktop-sdk.bst:components/openssh-systemd.bst",
    "bash-completion":            "freedesktop-sdk.bst:components/bash-completion.bst",
    "polkit":                     "freedesktop-sdk.bst:components/polkit.bst",
    "btrfs-progs":                "freedesktop-sdk.bst:components/btrfs-progs.bst",
    "udisks2":                    "freedesktop-sdk.bst:components/udisks.bst",
    "cups":                       "freedesktop-sdk.bst:components/cups-daemon.bst",
    "pipewire":                   "freedesktop-sdk.bst:components/pipewire-daemon.bst",
    "wireplumber":                "freedesktop-sdk.bst:components/wireplumber.bst",
    "mesa":                       "freedesktop-sdk.bst:vm/mesa-default.bst",
    "vulkan-headers":             "SKIP: build dep only, not runtime",
    "zip":                        "SKIP: freedesktop-sdk has unzip; zip available via homebrew",
    "wget":                       "SKIP: curl available via FDO; wget via homebrew",
    "xz":                         "SKIP: xz bundled in FDO runtime",

    # KDE packages → our BST elements
    "plasma-desktop":             "kde/plasma/plasma-desktop.bst (via org.kde.plasma.desktop.bst)",
    "plasma-wayland-session":     "kde/plasma/kwin.bst + session scripts",
    "sddm":                       "kde/plasma/sddm.bst",
    "kwin":                       "kde/plasma/kwin.bst",
    "plasma-pa":                  "kde/plasma/plasma-pa.bst",
    "plasma-nm":                  "kde/plasma/plasma-nm.bst",
    "plasma-systemmonitor":       "kde/plasma/plasma-systemmonitor.bst",
    "plasma-disks":               "kde/plasma/plasma-disks.bst",
    "plasma-firewall":            "kde/plasma/plasma-firewall.bst",
    "plasma-thunderbolt":         "kde/plasma/plasma-thunderbolt.bst",
    "plasma-vault":               "kde/plasma/plasma-vault.bst",
    "plasma-browser-integration": "kde/plasma/plasma-browser-integration.bst",
    "plasma-workspace":           "kde/plasma/plasma-workspace.bst",
    "bluedevil":                  "kde/plasma/bluedevil.bst",
    "breeze":                     "kde/plasma/breeze.bst",
    "breeze-gtk":                 "kde/plasma/breeze-gtk.bst",
    "powerdevil":                 "kde/plasma/powerdevil.bst",
    "kscreen":                    "kde/plasma/kscreen.bst",
    "dolphin":                    "kde/apps/dolphin.bst",
    "konsole":                    "kde/apps/konsole.bst",
    "kate":                       "kde/apps/kate.bst",
    "okular":                     "kde/apps/okular.bst",
    "gwenview":                   "kde/apps/gwenview.bst",
    "spectacle":                  "kde/apps/spectacle.bst",
    "kmail":                      "MISSING: kde/apps/kmail.bst not yet built",
    "kontact":                    "MISSING: kde/apps/kontact.bst not yet built",
    "korganizer":                 "MISSING: kde/apps/korganizer.bst not yet built",

    # Container/dev tools - not for Aurora (use homebrew)
    "docker":                     "SKIP: use homebrew or Flatpak for Docker",
    "docker-buildx":              "SKIP: dev tool → homebrew",
    "docker-compose":             "SKIP: dev tool → homebrew",
    "flatpak-builder":            "SKIP: dev tool → homebrew/Flatpak",
    "base-devel":                 "SKIP: Arch meta-package, dev tools → homebrew",
    "clang":                      "SKIP: dev tool → homebrew",
    "clazy":                      "SKIP: dev tool → homebrew",
    "cmake":                      "SKIP: dev tool → homebrew",
    "lldb":                       "SKIP: dev tool → homebrew",
    "llvm":                       "SKIP: dev tool → homebrew",
    "meson":                      "SKIP: dev tool → homebrew",
    "ninja":                      "SKIP: dev tool → homebrew",
    "perf":                       "SKIP: dev tool → homebrew",
    "strace":                     "SKIP: dev tool → homebrew",
    "subversion":                 "SKIP: dev tool → homebrew",
    "ccache":                     "SKIP: dev tool → homebrew",
    "bc":                         "SKIP: dev tool → homebrew",
    "boost":                      "SKIP: dev tool / build dep only",
    "boost-libs":                 "SKIP: covered by FDO/build deps",
    "glib2-devel":                "SKIP: build dep only",
    "yaml-cpp":                   "SKIP: build dep only",
    "gperf":                      "SKIP: build dep only",
    "intltool":                   "SKIP: build dep only",
    "reuse":                      "SKIP: dev tool → homebrew",
    "sassc":                      "SKIP: build dep only",
    "xerces-c":                   "SKIP: build dep only",
    "perl-uri":                   "SKIP: build dep only",
    "python-lxml":                "SKIP: build dep only",
    "python-yaml":                "SKIP: build dep only (kde-builder)",
    "python-setproctitle":        "SKIP: build dep only (kde-builder)",
    "python-atspi":               "SKIP: build dep only (selenium)",
    "ruby":                       "SKIP: dev tool",
    "ruby-stdlib":                "SKIP: dev tool",
    "qemu-desktop":               "SKIP: full QEMU, use Flatpak; agent: gnomeos-deps/qemu-guest-agent.bst",
    "crun":                       "SKIP: bundled with podman (freedesktop-sdk)",
    "systemd-bootchart":          "SKIP: profiling tool → homebrew",

    # Misc covered
    "zram-generator":             "gnomeos-deps/zram-generator.bst",
    "kmscon":                     "gnomeos-deps/kmscon.bst",
    "realtime-privileges":        "gnomeos-deps/realtime-privileges.bst",
    "distrobox":                  "gnomeos-deps/distrobox.bst",
    "toolbox":                    "gnomeos-deps/toolbox.bst",
    "xdg-utils":                  "SKIP: provided by FDO/KDE Plasma",
    "desktop-file-utils":         "SKIP: provided by FDO runtime",
    "words":                      "gnomeos-deps/words.bst (in gnome-build-meta)",
    "libratbag":                  "gnomeos-deps/libratbag.bst",
    "wireguard-tools":            "gnomeos-deps/wireguard-tools.bst",
    "ex-vi-compat":               "SKIP: vim covers this",
    "cpupower":                   "gnomeos-deps/cpupower.bst",
    "drm-info":                   "gnomeos-deps/drm-info.bst",
    "libva-utils":                "freedesktop-sdk.bst:extensions/vainfo/libva-utils.bst",
    "lshw":                       "gnomeos-deps/lshw.bst",
    "man-db":                     "freedesktop-sdk.bst:components/man-db.bst",
    "man-pages":                  "freedesktop-sdk.bst:components/man-pages.bst",
    "plocate":                    "freedesktop-sdk.bst:components/plocate.bst",
    "turbostat":                  "SKIP: x86-specific, part of linux-tools",
    "udftools":                   "gnomeos-deps/udftools.bst",
    "yubikey-manager":            "MISSING: needs python/libfido2 deps",
    "android-tools":              "gnomeos-deps/android-tools.bst",
    "alsa-utils":                 "gnomeos-deps/alsa-utils.bst",
    "cdemu-client":               "SKIP: virtual disc mounting → Flatpak",
    "espeak-ng":                  "gnomeos-deps/espeak-ng.bst",
    "fastfetch":                  "gnomeos-deps/fastfetch.bst",
    "bluez-utils":                "freedesktop-sdk.bst:components/bluez.bst (bluez-utils part of bluez)",
    "bat":                        "SKIP: fancy cat → homebrew",
    "duf":                        "SKIP: fancy df → homebrew",
    "fd":                         "SKIP: fancy find → homebrew",
    "fzf":                        "SKIP: fuzzy finder → homebrew",
    "gping":                      "SKIP: fancy ping → homebrew",
    "htop":                       "SKIP: fancy top → homebrew",
    "iotop":                      "SKIP: fancy top → homebrew",
    "mcfly":                      "SKIP: shell history → homebrew",
    "nvtop":                      "SKIP: GPU monitoring → homebrew",
    "procs":                      "SKIP: fancy ps → homebrew",
    "ripgrep":                    "SKIP: fancy grep → homebrew",
    "tldr":                       "SKIP: mini-manpages → homebrew",
    "trash-cli":                  "SKIP: safer rm → homebrew",
    "kdialog":                    "SKIP: part of KDE apps",
    "nvme-cli":                   "gnomeos-deps/nvme-cli.bst",

    # FDO-covered packages (in freedesktop-sdk, add to deps.bst to include)
    "kmod":                       "freedesktop-sdk.bst:components/kmod.bst",
    "lvm2":                       "freedesktop-sdk.bst:components/lvm2.bst",
    "tpm2-tss":                   "freedesktop-sdk.bst:components/tpm2-tss.bst",
    "e2fsprogs":                  "freedesktop-sdk.bst:components/e2fsprogs.bst",
    "xfsprogs":                   "freedesktop-sdk.bst:components/xfsprogs.bst",
    "dosfstools":                 "freedesktop-sdk.bst:components/dosfstools.bst",
    "erofs-utils":                "freedesktop-sdk.bst:components/erofs-utils.bst",
    "f2fs-tools":                 "freedesktop-sdk.bst:components/f2fs-tools.bst",
    "sbsigntools":                "freedesktop-sdk.bst:components/sbsigntools.bst",
    "libheif":                    "freedesktop-sdk.bst:components/libheif.bst",
    "libjxl":                     "freedesktop-sdk.bst:components/libjxl.bst",
    "libavif":                    "freedesktop-sdk.bst:components/libavif.bst",
    "hunspell":                   "freedesktop-sdk.bst:components/hunspell.bst",
    "geoclue":                    "freedesktop-sdk.bst:components/geoclue.bst",
    "man-db":                     "freedesktop-sdk.bst:components/man-db.bst",
    "man-pages":                  "freedesktop-sdk.bst:components/man-pages.bst",
    "plocate":                    "freedesktop-sdk.bst:components/plocate.bst",
    "ccid":                       "freedesktop-sdk.bst:components/ccid.bst",
    "libva":                      "freedesktop-sdk.bst:components/libva.bst",
    "libva-utils":                "freedesktop-sdk.bst:extensions/vainfo/libva-utils.bst",
    "vulkan-icd-loader":          "freedesktop-sdk.bst:components/vulkan-icd-loader.bst",
    "xorg-xwayland":              "freedesktop-sdk.bst:components/xwayland.bst",
    "wireless-regdb":             "freedesktop-sdk.bst:components/wireless-regdb-bin.bst (in deps.bst)",
    "edk2-ovmf":                  "freedesktop-sdk.bst:components/ovmf.bst (in deps.bst for x86_64)",
    "sane":                       "gnomeos-deps/sane-backends.bst + sane-airscan.bst (in deps.bst)",
    "bluez-utils":                "freedesktop-sdk.bst:components/bluez.bst (bluez-utils part of bluez)",
    "bluez-obex":                 "freedesktop-sdk.bst:components/bluez.bst (OBEX part of bluez)",
    "android-udev":               "gnomeos-deps/android-udev-rules.bst (in deps.bst)",

    # Name-mapped packages (Arch pkg name differs from our BST element name)
    "usb_modeswitch":             "gnomeos-deps/usb-modeswitch.bst",
    "noto-fonts-cjk":             "gnomeos-deps/noto-cjk.bst",
    "exfatprogs":                 "freedesktop-sdk.bst:components/exfat-progs.bst (in deps.bst)",
    "networkmanager-strongswan":  "gnomeos-deps/NetworkManager-strongswan.bst",
    "networkmanager-vpn-plugin-l2tp":         "gnomeos-deps/NetworkManager-l2tp.bst",
    "networkmanager-vpn-plugin-pptp":         "gnomeos-deps/NetworkManager-pptp.bst",
    "networkmanager-vpn-plugin-sstp":         "gnomeos-deps/NetworkManager-sstp.bst",
    "networkmanager-vpn-plugin-openconnect":  "gnomeos-deps/NetworkManager-openconnect.bst",
    "networkmanager-vpn-plugin-openvpn":      "gnomeos-deps/NetworkManager-openvpn.bst",
    "networkmanager-vpn-plugin-vpnc":         "gnomeos-deps/NetworkManager-vpnc.bst",

    # Pipewire sub-packages — all provided by FDO pipewire-daemon
    "pipewire-jack":              "freedesktop-sdk.bst:components/pipewire-daemon.bst (JACK compat libs included)",
    "pipewire-alsa":              "freedesktop-sdk.bst:components/pipewire-daemon.bst",
    "pipewire-pulse":             "freedesktop-sdk.bst:components/pipewire-daemon.bst",
    "pipewire-libcamera":         "freedesktop-sdk.bst:components/pipewire-daemon.bst",
    "pipewire-v4l2":              "freedesktop-sdk.bst:components/pipewire-daemon.bst",
    "pipewire-zeroconf":          "freedesktop-sdk.bst:components/pipewire-daemon.bst",

    # SKIP: DKMS kernel modules — not applicable to OCI bootc image
    "acpi_call-dkms":             "SKIP: kernel DKMS module, not applicable to OCI",
    "linux-apfs-rw-dkms":        "SKIP: kernel DKMS module, not applicable to OCI",
    "nvidia-open-dkms":           "SKIP: NVIDIA DKMS, not applicable to OCI",
    "v4l2loopback-utils":         "SKIP: DKMS virtual camera, not applicable to OCI",
    "openrazer-daemon":           "SKIP: Razer peripheral DKMS, not applicable to OCI",

    # SKIP: GPU driver variants — Mesa in FDO covers all GPU drivers
    "libva-intel-driver":         "SKIP: VA-API Intel driver covered by Mesa in FDO",
    "libva-mesa-driver":          "SKIP: VA-API Mesa driver covered by FDO Mesa build",
    "libva-nvidia-driver":        "SKIP: NVIDIA-specific, not in OCI image",
    "vulkan-intel":               "SKIP: Intel Vulkan (ANV) driver provided by FDO Mesa",
    "vulkan-radeon":              "SKIP: AMD Vulkan (RADV) driver provided by FDO Mesa",
    "vulkan-swrast":              "SKIP: Software rasterizer (lavapipe) in FDO Mesa",
    "nvidia-prime":               "SKIP: NVIDIA Optimus, not applicable to OCI image",
    "vpl-gpu-rt":                 "SKIP: Intel oneVPL GPU runtime, proprietary/x86-specific",

    # SKIP: Arch meta-packages
    "base":                       "SKIP: Arch Linux base meta-package",
    "kde-linux":                  "SKIP: Arch KDE Linux meta-package",

    # SKIP: Arch-specific / firmware
    "linux-firmware-marvell":     "SKIP: Marvell firmware included in linux-firmware",
    "yubikey-full-disk-encryption": "SKIP: Arch-specific full disk encryption tooling",
    "bmusb":                      "SKIP: BlackMagic USB, rare niche hardware",

    # SKIP: Virtualisation guests — not needed in OCI image
    "open-vm-tools":              "SKIP: VMware guest tools, not applicable to OCI",
    "virtualbox-guest-utils":     "SKIP: VirtualBox guest tools, use QEMU/KVM instead",
    "edk2-shell":                 "SKIP: UEFI interactive shell, only for VM debugging",

    # SKIP: Developer tools → use Flatpak or homebrew
    "gammaray":                   "SKIP: KDE developer introspection tool, use Flatpak",
    "podman-compose":             "SKIP: dev tool, use homebrew or Flatpak",

    # SKIP: niche/experimental pipewire backends
    "pipewire-ffado":             "SKIP: FireWire audio (FFADO), niche legacy hardware",
    "pipewire-roc":               "SKIP: ROC network audio streaming, experimental",

    # SKIP: Qt internal build artifact (not a separate runtime package)
    "qt6-multimedia-ffmpeg":      "SKIP: FFmpeg backend built into qt6-multimedia element",

    # SKIP: busybox not needed in full userland OCI image
    "busybox":                    "SKIP: full userland already present in OCI image",
}

# FDO element names → the FDO component path (to auto-detect FDO coverage)
FDO_PREFIX = "freedesktop-sdk.bst:components/"

def parse_mkosi_packages(conf_dir: Path) -> dict[str, list[str]]:
    """Return {conf_filename: [package, ...]} from all mkosi.conf.d/*.conf files."""
    result = {}
    for conf_file in sorted(conf_dir.glob("*.conf")):
        packages = []
        in_packages = False
        for line in conf_file.read_text().splitlines():
            stripped = line.strip()
            if stripped.startswith("Packages="):
                in_packages = True
                after_eq = stripped[len("Packages="):].strip()
                if after_eq and not after_eq.startswith("#"):
                    packages.append(after_eq.split()[0])
                continue
            if in_packages:
                if stripped.startswith("[") and stripped != "[Content]":
                    in_packages = False
                    continue
                if stripped and not stripped.startswith("#"):
                    pkg = stripped.split()[0].split("#")[0].strip()
                    if pkg:
                        packages.append(pkg)
        result[conf_file.name] = packages
    return result


def collect_bst_elements(elements_dir: Path) -> set[str]:
    """Return set of all .bst element paths relative to elements_dir."""
    elements = set()
    for bst_file in elements_dir.rglob("*.bst"):
        rel = bst_file.relative_to(elements_dir)
        elements.add(str(rel))
    return elements


def check_package(pkg: str, bst_elements: set[str]) -> tuple[str, str]:
    """
    Check if a package is covered in Aurora.
    Returns (status, note) where status is COVERED, SKIP, or MISSING.
    """
    # 1. Check manual map first
    if pkg in MANUAL_MAP:
        note = MANUAL_MAP[pkg]
        if note.startswith("SKIP"):
            return "SKIP", note[5:].lstrip(": ")
        if note.startswith("MISSING"):
            return "MISSING", note[8:].lstrip(": ")
        return "COVERED", note

    # 2. Try direct name match against gnomeos-deps/*.bst
    bst_name = f"gnomeos-deps/{pkg}.bst"
    if bst_name in bst_elements:
        return "COVERED", bst_name

    # 3. Try kde/* name matches (strip common distro prefixes like kf6-, plasma-)
    clean = re.sub(r"^(kf6-|plasma-|kde-|qt6-|python-)", "", pkg)
    for bst in bst_elements:
        basename = Path(bst).stem
        if basename == clean or basename == pkg:
            return "COVERED", bst

    # 4. Try FDO component name match
    fdo_candidate = f"freedesktop-sdk.bst:components/{pkg}.bst"
    # We don't have the full FDO list loaded, but we check deps.bst references
    # Just flag as needs-check
    return "MISSING", f"no BST element found (check FDO: {fdo_candidate})"


# BST elements that are intentional infrastructure/glue, not package mirrors
BST_INFRA_ELEMENTS = {
    "deps", "deps-aarch64", "deps-devel",
    "microcode",  # combines intel+amd ucode
    # system configuration elements (not packages, just config/preset files)
    "debuginfod-config", "disable-iscsi", "fake-toolbox-env",
    "flathub-beta-config", "flathub-config",
    "geoclue-base", "hidraw-udev", "journald-config", "ld-config",
    "modprobe-config", "nano-default-editor", "nm-connectivity-config",
    "pcrlock-config", "preset-all", "sysext-utils", "sysupdate-config",
    "udev-hide-usr", "vte-config", "wpa-supplicant-config",
    "shim-maybe",  # conditional shim loader
    "plymouth-gnome-theme",  # config/theme file overlay
}

# gnomeos-deps packages that are known intentional Aurora additions
# (not in mkosi because Aurora adds them on top of the KDE Linux base)
BST_AURORA_EXTRAS = {
    "fish",                      # better shell UX, Aurora choice
    "noise-suppression-for-voice",  # mic noise reduction
    "uinput",                    # controller emulation
    "firewalld",                 # Aurora uses firewalld alongside/instead of ufw
    "just",                      # task runner used in this project
    "bootc",                     # OCI/bootc image tool — core of the build pipeline
    # NVIDIA support stack
    "nvidia-drivers", "nvidia-drivers-libs", "nvidia-drivers-modules",
    "nvidia-container-toolkit",
    # CJK fonts for international users
    "noto-cjk",
    # NM VPN plugins (Aurora ships full VPN support)
    "NetworkManager-l2tp", "NetworkManager-openconnect",
    "NetworkManager-openvpn", "NetworkManager-pptp", "NetworkManager-sstp",
    "NetworkManager-strongswan", "NetworkManager-vpnc",
    # Hardware support extras
    "android-udev-rules", "usb-modeswitch", "alsa-ucm-conf",
    # Smart card / security
    "opensc", "pam-pkcs11",
    # Scanner support
    "sane-backends", "sane-airscan",
    # System tools
    "bpftop", "uresourced", "upower",
    "qemu-user",
    "wsdd",  # Windows service discovery (Samba-related)
    # Snapd — inherited from gnome-build-meta for gnomeos/snapd/ path, not in aurora
    "snapd",
}

# gnomeos-deps packages that are transitive build/runtime deps (not top-level packages)
# These are correct to have even if mkosi doesn't list them — they're pulled in by
# packages that ARE in mkosi.
BST_TRANSITIVE_DEPS = {
    # fprintd deps
    "libfprint", "python-libfprint",
    # iio-sensor-proxy deps
    # android-udev-rules has no deps
    # fcitx5 cluster deps
    "fcitx5-chinese-addons", "fcitx5-configtool", "fcitx5-gtk", "fcitx5-qt",
    "libime", "lua-lpeg",
    # printing deps
    "foomatic-db-engine", "gutenprint", "hplip", "splix",
    # plymouth
    "plymouth",
    # hardware
    "bolt",
    # system tools
    "lm_sensors", "smartmontools", "nvme-cli", "hdparm",
    "pciutils", "dmidecode", "acpica",
    # network
    "avahi", "nss-mdns",
    "libnl", "iw",
    # misc
    "squashfuse", "libsquashfs",
    "power-profiles-daemon",
    "thermald",
    "xdg-desktop-portal-kde",
    "xdg-desktop-portal",
    # VPN backend libraries (deps of NM VPN plugins)
    "openvpn", "openconnect", "vpnc", "vpnc-scripts",
    "strongswan", "xl2tpd",
    # iMobileDevice chain (iPhone USB sync support)
    "libimobiledevice", "libplist", "libusbmuxd",
    # Static / build-time only libs
    "pcre2-static", "glib-static", "zlib-ng-static",
    # Image/media processing deps
    "imath",       # dep of openexr
    "leptonica",   # dep of tesseract-ocr
    "libopusenc",  # dep of opus-tools
    # Misc runtime deps
    "libssc",          # dep of libimobiledevice
    "libtsm",          # terminal state machine (dep of kgx or similar)
    "libtpms",         # dep of swtpm (TPM emulator)
    "ayatana-ido",     # dep of libayatana-indicator
    "libayatana-indicator",  # dep of indicator-based apps
    "python3-zstd",    # dep of something in python stack
    "iucode-tool",     # microcode loading tool (dep of microcode element)
    "bindfs",          # FUSE bindfs (dep of rootless container support)
    "nftables",        # dep of firewalld
}


def _run_extra_check(mkosi_pkgs: dict, bst_elements: set) -> None:
    """
    Reverse parity check: find gnomeos-deps BST elements that are NOT
    in KDE Linux mkosi. Print them with a classification.
    """
    # Collect all mkosi package names (flat set)
    mkosi_all: set[str] = set()
    for pkgs in mkosi_pkgs.values():
        mkosi_all.update(pkgs)

    # Also flatten MANUAL_MAP covered/skip entries — their package names are in mkosi
    # Build a set of package names that are explicitly mapped (means they ARE in mkosi)
    mapped_names = set(MANUAL_MAP.keys())

    # Collect gnomeos-deps .bst stem names
    gnomeos_bst: list[str] = []
    for elem in sorted(bst_elements):
        if elem.startswith("gnomeos-deps/") and not elem.endswith(("/",)):
            stem = Path(elem).stem
            gnomeos_bst.append(stem)

    RESET = "\033[0m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"
    CYAN = "\033[36m"

    header = f"{'BST element':<40}  {'Classification':<14}  Note"
    sep = "-" * min(len(header) + 20, 110)
    print(sep)
    print("gnomeos-deps elements NOT in KDE Linux mkosi")
    print(sep)
    print(header)
    print(sep)

    counts = {"IN_MKOSI": 0, "INFRA": 0, "AURORA_EXTRA": 0, "TRANSITIVE": 0, "UNKNOWN": 0}
    unknown_list = []

    for stem in gnomeos_bst:
        in_mkosi = stem in mkosi_all or stem in mapped_names
        if in_mkosi:
            counts["IN_MKOSI"] += 1
            continue  # Only report elements NOT in mkosi

        if stem in BST_INFRA_ELEMENTS:
            color, label, note = CYAN, "INFRA", "BuildStream glue element, not a package"
            counts["INFRA"] += 1
        elif stem in BST_AURORA_EXTRAS:
            color, label, note = GREEN, "AURORA_EXTRA", "Intentional Aurora addition beyond KDE Linux base"
            counts["AURORA_EXTRA"] += 1
        elif stem in BST_TRANSITIVE_DEPS:
            color, label, note = YELLOW, "TRANSITIVE", "Dependency of a listed package"
            counts["TRANSITIVE"] += 1
        else:
            color, label, note = RED, "UNKNOWN", "Not in mkosi — review if needed"
            counts["UNKNOWN"] += 1
            unknown_list.append(stem)

        print(f"{stem:<40}  {color}{label:<14}{RESET}  {note}")

    print(sep)
    total_not_in_mkosi = counts["INFRA"] + counts["AURORA_EXTRA"] + counts["TRANSITIVE"] + counts["UNKNOWN"]
    print(f"\ngnomeos-deps total: {len(gnomeos_bst)}  |  In mkosi: {counts['IN_MKOSI']}  |  "
          f"Not in mkosi: {total_not_in_mkosi}")
    print(f"  {CYAN}INFRA: {counts['INFRA']}{RESET}  "
          f"{GREEN}AURORA_EXTRA: {counts['AURORA_EXTRA']}{RESET}  "
          f"{YELLOW}TRANSITIVE: {counts['TRANSITIVE']}{RESET}  "
          f"{RED}UNKNOWN: {counts['UNKNOWN']}{RESET}")

    if unknown_list:
        print(f"\n{RED}=== UNKNOWN packages — review these ==={RESET}")
        for stem in sorted(unknown_list):
            print(f"  {stem}")
        print(f"\nThese {len(unknown_list)} packages are in our BST but not in KDE Linux mkosi.")
        print("Consider: remove them, move to AURORA_EXTRAS list, or add to TRANSITIVE_DEPS.")
    else:
        print(f"\n{GREEN}All non-mkosi packages are accounted for.{RESET}")



def main():
    parser = argparse.ArgumentParser(description="Aurora ↔ KDE Linux mkosi parity checker")
    parser.add_argument("--missing-only", action="store_true",
                        help="Show only MISSING packages")
    parser.add_argument("--csv", action="store_true",
                        help="Output as CSV")
    parser.add_argument("--versions", action="store_true",
                        help="Show BST version and Arch Linux version for each package "
                             "(fetches from archlinux.org; requires internet)")
    parser.add_argument("--extra", action="store_true",
                        help="Reverse check: show gnomeos-deps BST elements NOT in KDE Linux mkosi. "
                             "Helps identify packages that may have snuck in unnecessarily.")
    args = parser.parse_args()

    if not MKOSI_CONF_DIR.exists():
        print(f"ERROR: KDE Linux mkosi not found at {MKOSI_CONF_DIR}", file=sys.stderr)
        print("Clone it with: git clone --depth=1 https://invent.kde.org/kde-linux/kde-linux.git /tmp/kde-linux",
              file=sys.stderr)
        sys.exit(1)

    mkosi_pkgs = parse_mkosi_packages(MKOSI_CONF_DIR)
    bst_elements = collect_bst_elements(BST_ELEMENTS_DIR)

    if args.extra:
        _run_extra_check(mkosi_pkgs, bst_elements)
        return

    all_pkgs = []  # (conf_file, pkg, status, note, bst_ver, arch_ver)
    seen = set()

    for conf_name, pkgs in mkosi_pkgs.items():
        for pkg in pkgs:
            if pkg in seen:
                continue
            seen.add(pkg)
            status, note = check_package(pkg, bst_elements)
            all_pkgs.append((conf_name, pkg, status, note, None, None))

    if args.versions:
        # BST versions — fast local parsing
        for i, (conf, pkg, status, note, _, _) in enumerate(all_pkgs):
            bst_path = find_bst_file_for_package(pkg, bst_elements)
            bst_ver = extract_bst_version(bst_path) if bst_path else None
            all_pkgs[i] = (conf, pkg, status, note, bst_ver, None)

        # Arch versions — concurrent network fetching
        all_pkg_names = [row[1] for row in all_pkgs]
        arch_vers = fetch_arch_versions_bulk(all_pkg_names)
        for i, (conf, pkg, status, note, bst_ver, _) in enumerate(all_pkgs):
            all_pkgs[i] = (conf, pkg, status, note, bst_ver, arch_vers.get(pkg))

    # Summary counts
    counts = {"COVERED": 0, "SKIP": 0, "MISSING": 0}
    for _, _, status, _, _, _ in all_pkgs:
        counts[status] += 1

    if args.csv:
        if args.versions:
            print("conf_file,package,status,note,bst_version,arch_version")
        else:
            print("conf_file,package,status,note")
        for conf, pkg, status, note, bst_ver, arch_ver in all_pkgs:
            if args.missing_only and status != "MISSING":
                continue
            if args.versions:
                print(f"{conf},{pkg},{status},{note!r},{bst_ver or ''},{arch_ver or ''}")
            else:
                print(f"{conf},{pkg},{status},{note!r}")
        return

    # Pretty table
    STATUS_COLOR = {
        "COVERED": "\033[32m",   # green
        "SKIP":    "\033[33m",   # yellow
        "MISSING": "\033[31m",   # red
    }
    RESET = "\033[0m"

    if args.versions:
        header = f"{'Package':<32}  {'Status':<8}  {'BST ver':<14}  {'Arch ver':<14}  Note"
        sep = "-" * min(len(header) + 20, 120)
        print(sep)
        print(header)
        print(sep)
        for conf, pkg, status, note, bst_ver, arch_ver in all_pkgs:
            if args.missing_only and status != "MISSING":
                continue
            color = STATUS_COLOR.get(status, "")
            bv = bst_ver or "-"
            av = arch_ver or "-"
            # Flag version mismatch in yellow
            mismatch = ""
            if bst_ver and arch_ver and bst_ver != arch_ver:
                mismatch = f"  \033[33m(Arch: {arch_ver})\033[0m"
            print(f"{pkg:<32}  {color}{status:<8}{RESET}  {bv:<14}  {av:<14}  {note}{mismatch}")
    else:
        col_w = [20, 30, 8, 0]
        header = f"{'Conf file':<{col_w[0]}}  {'Package':<{col_w[1]}}  {'Status':<{col_w[2]}}  Note"
        sep = "-" * len(header)
        print(sep)
        print(header)
        print(sep)
        for conf, pkg, status, note, bst_ver, arch_ver in all_pkgs:
            if args.missing_only and status != "MISSING":
                continue
            color = STATUS_COLOR.get(status, "")
            print(f"{conf:<{col_w[0]}}  {pkg:<{col_w[1]}}  {color}{status:<{col_w[2]}}{RESET}  {note}")

    print(sep)
    total = sum(counts.values())
    print(f"\nTotal: {total}  |  "
          f"\033[32mCOVERED: {counts['COVERED']}\033[0m  |  "
          f"\033[33mSKIP: {counts['SKIP']}\033[0m  |  "
          f"\033[31mMISSING: {counts['MISSING']}\033[0m")
    print()

    if counts["MISSING"] > 0:
        print("=== MISSING packages (need BST elements) ===")
        for _, pkg, status, note, _, _ in all_pkgs:
            if status == "MISSING":
                print(f"  {pkg:30s}  {note}")

if __name__ == "__main__":
    main()
