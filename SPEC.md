# KDE Linux BuildStream — Project Specification

## Vision

Fork `gnome-build-meta` (the BuildStream project that produces GNOME OS) and replace
all GNOME-specific packages with KDE packages sourced from the official
[KDE Linux](https://invent.kde.org/kde-linux/kde-linux) distribution.
The result is a bootable OCI/bootc image produced with BuildStream — identical
build methodology to GNOME OS and Project Bluefin's dakota, but running
KDE Plasma instead of GNOME Shell.

---

## Source Repositories

| Repo | Role |
|------|------|
| `https://gitlab.gnome.org/GNOME/gnome-build-meta` | Upstream — **fork this** |
| `https://gitlab.freedesktop.org/freedesktop-sdk/freedesktop-sdk` | Base SDK (Qt6, systemd, kernel…) — **junction, not forked** |
| `https://invent.kde.org/kde-linux/kde-linux` | KDE Linux — **authoritative package list** |
| `https://invent.kde.org/kde-linux/kde-linux-packages` | KDE packages built by kde-builder — **reference** |
| `https://github.com/projectbluefin/dakota` | Bluefin — **Justfile copied** |
| `https://github.com/hanthor/kde-linux` | **Our output repo** |

---

## Architecture Overview

```
hanthor/kde-linux
├── project.conf                 # Project config (forked from gnome-build-meta)
├── Justfile                     # Build commands (from dakota; s/bluefin/kde-linux)
├── elements/
│   ├── freedesktop-sdk.bst      # Junction → freedesktop-sdk (same as upstream)
│   ├── kde-build-meta.bst       # Junction → hanthor/kde-build-meta (our gnome-build-meta fork)
│   ├── kde/                     # KDE-specific overrides & new elements
│   │   ├── deps.bst             # Master KDE deps stack (replaces gnomeos-deps/deps.bst)
│   │   ├── plasma/              # Plasma 6 elements (plasma-workspace, kwin, plasmashell…)
│   │   ├── frameworks/          # KDE Frameworks 6 elements
│   │   ├── apps/                # KDE Applications (dolphin, konsole, kate…)
│   │   ├── sddm.bst             # Display manager
│   │   └── kde-gtk-config.bst   # GTK integration
│   └── oci/
│       ├── kde-linux.bst        # Main build target (replaces oci/gnomeos/image.bst)
│       ├── os-release.bst       # KDE Linux os-release
│       └── layers/
│           ├── kde-runtime.bst
│           ├── kde-plasma.bst
│           └── kde-apps.bst
├── files/                       # Static config files
│   ├── sddm/                    # SDDM config
│   └── plasma/                  # Plasma default settings
├── patches/                     # Patches for upstream junctions
└── include/
    └── aliases.yml              # URL aliases
```

### Two-Repo Model

```
hanthor/kde-build-meta   (fork of GNOME/gnome-build-meta)
  └── replaces GNOME shell/apps/display-manager with KDE equivalents
  └── keeps: freedesktop-sdk junction, systemd, pipewire, kernel, bootc…
  └── removes: GNOME Shell, Mutter, GDM, GNOME apps, gnome-settings-daemon

hanthor/kde-linux        (fork of projectbluefin/dakota)
  └── junction → hanthor/kde-build-meta
  └── junction → freedesktop-sdk
  └── adds: KDE-specific deps, Justfile, CI, VM tooling
```

---

## KDE Package Source (Authoritative)

All KDE package versions and selections come from
`invent.kde.org/kde-linux/kde-linux`. The package groups map to:

### Core (from `mkosi.conf.d/00-packages-core.conf`)
These are kept as-is from gnome-build-meta / freedesktop-sdk where possible.
New `.bst` elements needed only where not already in freedesktop-sdk:

| Package | Source | Status |
|---------|--------|--------|
| `linux-zen` | freedesktop-sdk kernel element | existing, pin version |
| `systemd`, `systemd-ukify` | `freedesktop-sdk.bst:components/systemd.bst` | existing |
| `plymouth` | `freedesktop-sdk.bst:components/plymouth.bst` | existing |
| `efibootmgr` | custom `.bst` (currently in dakota) | copy from dakota |
| `flatpak` | `freedesktop-sdk.bst:components/flatpak.bst` | existing |
| `mesa`, `vulkan-*` | `freedesktop-sdk.bst:vm/mesa-default.bst` | existing |
| `cups`, cups-browsed | `freedesktop-sdk.bst:components/cups.bst` | existing |
| `pipewire*`, `wireplumber` | `freedesktop-sdk.bst:components/pipewire*` | existing |
| `nvidia-open-dkms` | `gnome-build-meta:gnomeos/nvidia-drivers.bst` | fork+adapt |
| `fprintd` | `gnome-build-meta:gnomeos-deps/fprintd.bst` | fork+adapt |
| `iio-sensor-proxy` | `gnome-build-meta:gnomeos-deps/iio-sensor-proxy.bst` | fork+adapt |
| `mokutil` | `gnome-build-meta:gnomeos-deps/mokutil.bst` | fork+adapt |
| `fwupd` | `freedesktop-sdk.bst:components/fwupd.bst` | existing |
| `swtpm`, `virtiofsd` | existing gnomeos-deps elements | fork+adapt |
| `zram-generator` | `gnome-build-meta:gnomeos-deps/zram-generator.bst` | fork+adapt |
| `android-udev-rules` | `gnome-build-meta:gnomeos-deps/android-udev-rules.bst` | fork+adapt |
| `kmod`, `lvm2`, `btrfs-progs` | freedesktop-sdk | existing |

### Middleware (from `mkosi.conf.d/20-packages-middleware.conf`)

| Package | Source | Status |
|---------|--------|--------|
| `networkmanager-*-vpn` | gnomeos-deps NetworkManager-*.bst | fork+adapt |
| `pipewire-*` (alsa, jack, pulse, v4l2) | freedesktop-sdk components | existing |
| `xorg-xwayland` | `freedesktop-sdk.bst:components/xwayland.bst` | existing |
| `geoclue` | `freedesktop-sdk.bst:components/geoclue.bst` | existing |
| `hunspell` | freedesktop-sdk | existing |
| `nss-mdns` | gnomeos-deps/nss-mdns.bst | fork+adapt |
| `noto-fonts*` | gnomeos-deps/noto-cjk.bst + freedesktop-sdk | existing/adapt |
| `qt6-multimedia-ffmpeg` | freedesktop-sdk qt6 | existing |
| `appmenu-gtk-module`, `libdbusmenu-gtk3` | new `.bst` elements | **new** |
| `xdg-desktop-portal` | `freedesktop-sdk.bst:components/xdg-desktop-portal.bst` | existing |
| `xdg-desktop-portal-gtk` | `gnome-build-meta:core-deps/xdg-desktop-portal-gtk.bst` | fork+keep |
| `fwupd` (discover backend) | existing | existing |
| `switcheroo-control` | gnomeos-deps/switcheroo-control.bst | fork+adapt |
| `samba`, `ufw` | new `.bst` elements | **new** |
| `dnsmasq` | gnome-build-meta:core-deps/dnsmasq.bst | fork+keep |

### KDE Platform (from `mkosi.conf.d/40-packages-kde.conf`)

The KDE Linux distro builds these from source using `kde-builder`. In our
BuildStream world each becomes a `.bst` element. We take the exact versions
shipped in the latest `storage.kde.org/kde-linux-packages` pacman repo.

**KDE Frameworks 6** (all are cmake builds against Qt 6.9.x):

```
karchive          kauth              kbookmarks         kcodecs
kcompletion       kconfig            kconfigwidgets     kcoreaddons
kcrash            kdbusaddons        kdeclarative       kded
kdelibs4support   kdoctools          kglobalaccel       kguiaddons
ki18n             kiconthemes        kidletime          kimageformats
kio               kirigami2          kitemmodels        kitemviews
kjobwidgets       kjs                kjsembed           kmediaplayer
kmultisensorgrapher    knewstuff      knotifications     knotifyconfig
kpackage          kparts             kpeople            kpty
kquickcharts      krunner            kservice           kstatusnotifieritem
ksyntaxhighlighting   ktexteditor    ktextwidgets       kunitconversion
kuserfeedback     kwallet            kwidgetsaddons     kwindowsystem
kxmlgui           layer-shell-qt    libkdegames         libkscreen
libksane          libplasma          modemmanager-qt    networkmanager-qt
oxygen-icons5     phonon             plasma-activities  plasma-wayland-protocols
purpose            solid             syndication        syntax-highlighting
threadweaver
```

**KDE Plasma 6**:
```
bluedevil              breeze                  breeze-gtk
breeze-plymouth        discover                drkonqi
kactivitymanagerd      kde-cli-tools          kde-gtk-config
kde-inotify-survey    kdeplasma-addons        kgamma
kinfocenter            kmenuedit               kpipewire
kscreen                kscreenlocker           ksshaskpass
ksystemstats           kwallet-pam             kwayland
kwin                   layer-shell-qt          libkscreen
libplasma              milou                   oxygen
plasma-browser-integration     plasma-desktop
plasma-disks           plasma-firewall          plasma-framework
plasma-integration     plasma-login-manager    plasma-nm
plasma-pa              plasma-printer-manager  plasma-systemmonitor
plasma-thunderbolt     plasma-vault            plasma-welcome
plasma-workspace       plasma-workspace-wallpapers   polkit-kde-agent-1
powerdevil             print-manager           sddm                sddm-kcm
systemsettings         xdg-desktop-portal-kde
```

**KDE Applications**:
```
ark           dolphin       elisa         filelight
gwenview      haruna        k3b           kaddressbook
kate          kcalc         kcolorchooser kdialog
kfind         kfloppy       kget          kgpg
khelpcenter   kmail         kmix          kolourpaint
konsole       kontact       korganizer    kpat
kreadconfig   krecorder     krename       kruler
ksystemlog    kwalletmanager         kweather
okular        plasma-systemmonitor   qrca         spectacle
```

**Build flags from `extra-projects.yaml`**:
```yaml
discover:         -DBUILD_SystemdSysupdateBackend=ON
plasma-desktop:   -DBUILD_KCM_TOUCHPAD_X11=OFF -DBUILD_KCM_MOUSE_X11=OFF
plasma-workspace: -DWITH_X11_SESSION=OFF
plasma-login-manager: -DPAM_OS_CONFIGURATION=kde-linux
konsole:          -DWITH_KAPSULE=ON
```

### CLI Tools (from `mkosi.conf.d/80-packages-cli.conf`)

Most are already in freedesktop-sdk. New `.bst` elements needed for:
`bat`, `duf`, `fastfetch`, `fzf`, `gping`, `htop`, `iotop`, `mcfly`,
`nvtop`, `procs`, `ripgrep`, `tldr`, `trash-cli`, `zsh`, `zsh-*`

### Flatpak Apps (from `mkosi.postinst.chroot`)

Installed at runtime (not built by BuildStream), but we wire up the remotes:
- `flathub` — `org.kde.kwrite`, `org.mozilla.firefox`, GTK Breeze theme
- Nightly KDE repos — `ark`, `gwenview`, `kcalc`, `haruna`, `okular`, `qrca`

---

## GNOME → KDE Replacements

| GNOME element | Remove? | KDE replacement |
|---------------|---------|-----------------|
| `core/gnome-shell.bst` | ✂ remove | `kde/plasma/plasma-workspace.bst` |
| `core/mutter.bst` | ✂ remove | `kde/plasma/kwin.bst` |
| `core/gdm.bst` | ✂ remove | `kde/sddm.bst` |
| `core/gnome-control-center.bst` | ✂ remove | `kde/plasma/systemsettings.bst` |
| `core/gnome-settings-daemon.bst` | ✂ remove | `kde/plasma/plasma-workspace.bst` (settings built in) |
| `core/gnome-session.bst` | ✂ remove | `kde/plasma/plasma-workspace.bst` |
| `core/gnome-bluetooth.bst` | ✂ remove | `kde/plasma/bluedevil.bst` |
| `core/gnome-software.bst` | ✂ remove | `kde/plasma/discover.bst` |
| `core/gnome-keyring.bst` | ✂ remove | `kde/plasma/kwallet.bst` |
| `core/nautilus.bst` | ✂ remove | `kde/apps/dolphin.bst` |
| `core/gnome-text-editor.bst` | ✂ remove | `kde/apps/kate.bst` |
| `core/gnome-calculator.bst` | ✂ remove | `kde/apps/kcalc.bst` |
| `core/papers.bst` (doc viewer) | ✂ remove | `kde/apps/okular.bst` |
| `core/loupe.bst` (image viewer) | ✂ remove | `kde/apps/gwenview.bst` |
| `core/showtime.bst` (video) | ✂ remove | `kde/apps/haruna.bst` |
| `core/gnome-console.bst` | ✂ remove | `kde/apps/konsole.bst` |
| `core/snapshot.bst` (camera) | ✂ remove | *(Flatpak or Kdenlive later)* |
| `core/orca.bst` | keep | keep as `kde/orca.bst` |
| `gnomeos-deps/plymouth-gnome-theme.bst` | ✂ remove | `kde/breeze-plymouth.bst` |
| `gnomeos-deps/gnome-mimeapps.bst` | ✂ remove | *(KDE sets mime defaults via plasma)* |
| `core-deps/xdg-desktop-portal-gnome.bst` | ✂ remove | `kde/plasma/xdg-desktop-portal-kde.bst` |
| `core/gnome-initial-setup.bst` | ✂ remove | `kde/plasma/plasma-welcome.bst` |
| `core/gdm.bst` | ✂ remove | `kde/sddm.bst` |
| `incubator/meta-gnome-incubator-apps.bst` | ✂ remove | *(not applicable)* |

**Kept as-is from gnome-build-meta** (GNOME-neutral infrastructure):
- `freedesktop-sdk.bst` junction
- `gnomeos-deps/bootc.bst`
- `gnomeos-deps/fprintd.bst`
- `gnomeos-deps/iio-sensor-proxy.bst`
- `gnomeos-deps/kmscon.bst`
- `gnomeos-deps/android-udev-rules.bst`
- `gnomeos-deps/nss-mdns.bst`
- `gnomeos-deps/spice-vdagent.bst`
- `gnomeos-deps/virtiofsd.bst`
- `gnomeos-deps/swtpm.bst`
- `gnomeos-deps/switcheroo-control.bst`
- `gnomeos-deps/noto-cjk.bst`
- `gnomeos-deps/nvme-cli.bst`
- `gnomeos-deps/firewalld.bst`
- `gnomeos-deps/distrobox.bst`
- `gnomeos-deps/toolbox.bst`
- `core-deps/dnsmasq.bst`
- `core-deps/boltd.bst`
- `core-deps/xdg-desktop-portal-gtk.bst` (needed for GTK Flatpaks)
- All NetworkManager VPN elements
- `oci/gnomeos/init-scripts.bst` (adapt, keep structure)
- `oci/platform/image.bst` (keep as parent)

---

## Build Sequence

```
Phase 1 — Fork & skeleton
  1a. Fork gnome-build-meta → hanthor/kde-build-meta  (gh fork)
  1b. Create hanthor/kde-linux fresh (already done)
  1c. Copy Justfile from dakota; s/bluefin/kde-linux throughout

Phase 2 — kde-build-meta surgery
  2a. In kde-build-meta: delete all GNOME-specific elements listed above
  2b. Create elements/kde/ directory structure
  2c. Write .bst files for each KDE Plasma 6 component (cmake build)
  2d. Write .bst files for each KDE App
  2e. Write elements/kde/deps.bst  (replaces gnomeos-deps/deps.bst)
  2f. Adapt oci/gnomeos/stack.bst to pull kde/deps.bst instead
  2g. Adapt oci/integration/os-release.bst → KDE Linux branding

Phase 3 — kde-linux wiring
  3a. elements/kde-build-meta.bst  junction → hanthor/kde-build-meta
  3b. elements/oci/kde-linux.bst   (adapted from gnomeos/image.bst)
  3c. project.conf  (adapted from gnome-build-meta; change project name)

Phase 4 — First build
  4a. just bst build oci/kde-linux.bst
  4b. Fix dependency errors iteratively
  4c. just export
  4d. just generate-bootable-image
  4e. just boot-vm

Phase 5 — Iterate until Plasma boots in QEMU
  5a. Fix SDDM startup, KWin compositor, Plasma shell launch
  5b. Verify Dolphin, Konsole, Discover work
  5c. Verify Flatpak + flathub remote setup

Phase 6 — CI + polish
  6a. GitHub Actions workflow (copy from dakota, adapt)
  6b. Renovate config for dependency tracking
  6c. README.md
```

---

## Key `.bst` Element Patterns

### KDE cmake element template
```yaml
kind: cmake
sources:
- kind: git_repo
  url: kde:plasma/kwin.git    # (or kde:frameworks/kconfig.git)
  ref: v6.3.x                 # exact tag from kde-linux-packages
variables:
  cmake-options: >-
    -DCMAKE_INSTALL_PREFIX=/usr
    -DBUILD_TESTING=OFF
```

### URL alias needed in `include/aliases.yml`
```yaml
kde: https://invent.kde.org/
```

### Versions to pin
Exact versions come from `https://storage.kde.org/kde-linux-packages/testing/repo/packages/`
and the `build_date.txt` pinned by `bootstrap.sh`. We will scrape the package
database to get the exact `pkgver` for each component and pin those in the
`.bst` refs.

---

## Repository Setup Steps (Execution Order)

```bash
# 1. Fork gnome-build-meta to hanthor org
gh repo fork GNOME/gnome-build-meta --org hanthor --fork-name kde-build-meta

# 2. Clone both
git clone https://github.com/hanthor/kde-build-meta
git clone https://github.com/hanthor/kde-linux   # already exists

# 3. In kde-build-meta: create a new branch 'kde-linux'
cd kde-build-meta && git checkout -b kde-linux

# 4. Delete GNOME elements, add KDE elements
# 5. Push

# 6. In kde-linux:
#    - elements/kde-build-meta.bst references hanthor/kde-build-meta@kde-linux
#    - Copy Justfile from dakota
#    - Write project.conf
#    - Write elements/oci/kde-linux.bst
#    - Write elements/kde/deps.bst
```

---

## Open Questions / Decisions Needed

1. **KDE Frameworks versions**: Use whatever kde-linux-packages repo is
   currently shipping (latest stable Plasma 6.x / Frameworks 6.x). Do you
   want to track `master` or pin to the last known-good release?

2. **Wayland-only vs X11**: KDE Linux ships Wayland-only (`-DWITH_X11_SESSION=OFF`).
   Should we follow the same? **Recommended: yes**, matches upstream.

3. **Input methods**: KDE Linux ships `fcitx5` + `ibus` backends. Keep both?

4. **Flatpak apps baked in vs runtime**: KDE Linux downloads Flatpaks at image
   build time via `mkosi.postinst.chroot`. BuildStream can replicate this in a
   script element. Do you want these baked in or rely on the user setting up Flatpak?

5. **Artifact cache**: GNOME has `gbm.gnome.org` as a CAS. We won't have one
   initially — first build will compile everything from source (~many hours).
   Should we set up a GitHub Actions cache or just accept the cold build?
