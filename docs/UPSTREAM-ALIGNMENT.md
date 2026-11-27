# Upstream alignment: KDE Linux BuildStream and Dakota

- Status: plan, in progress
- Date of the survey: 2026-11-25
- Issue for this plan: [tuna-os/tromso#521](https://github.com/tuna-os/tromso/issues/521)
- Earlier decision: [ADR 0003](adr/0003-kde-buildstream-upstream-watch.md) and
  [tuna-os/tromso#85](https://github.com/tuna-os/tromso/issues/85)

This document records the official BuildStream work of KDE Linux. It compares
Tromsø with that work and with `projectbluefin/dakota`. It then gives a
migration plan in small steps.

All upstream data comes from read-only clones made on 2026-11-25. Each claim
gives a repository, a branch and a commit.

## 1. The official upstream

### 1.1 Three repositories, one chain

The official work is not one branch. It is a chain of three BuildStream
projects on `invent.kde.org`. Each project is a junction of the next project.

| Layer | Repository and branch | Commit on 2026-11-25 | Content |
|---|---|---|---|
| Image | [`kde-linux/kde-linux`](https://invent.kde.org/kde-linux/kde-linux/-/tree/buildstream), branch `buildstream` | `8c2dec7` (2026-11-19) | 16 `os/` elements, `build.sh`, mkosi configuration, Calamares configuration |
| KDE payload | [`kde-linux/kde-linux-packages`](https://invent.kde.org/kde-linux/kde-linux-packages/-/tree/buildstream), branch `buildstream` | `1614788` (2026-11-20) | 1 payload element that runs kde-builder, 2 local plugins |
| Recipes | [`packaging/kde-buildstream`](https://invent.kde.org/packaging/kde-buildstream), branch `master` | `ee0596e` (2026-11-19) | 179 `components/`, 39 `qt/`, 6 `os/` stacks |
| Base | `freedesktop-sdk`, branch `release/26.08` | `freedesktop-sdk-26.08.4-216-ge21dcfd` | junction of `kde-buildstream` |
| Base extras | `freedesktop-sdk-extra`, branch `main` | `freedesktop-sdk-extra-26.08.4-132-ge535b71` | junction of `kde-buildstream` |

Notes:

- The junction in `kde-linux-packages` uses the URL
  `invent:sitter/kde-buildstream.git`. This URL and
  `packaging/kde-buildstream` give the same commit `ee0596e`. The first URL
  is the old location.
- `kde-linux` `master` is the main line. It uses mkosi and Arch Linux
  packages. The `buildstream` branch is 66 commits ahead of `master` and 13
  commits behind it.
- The `buildstream` branch publishes a different edition with the name
  `testing-buildstream`. See `.kde-linux-metadata` on that branch.

### 1.2 Evidence that the work is official

- Issue [kde-linux#727 "BuildStream"](https://invent.kde.org/kde-linux/kde-linux/-/issues/727)
  by Harald Sitter (2026-07-27) announces the work. It gives the images at
  `https://kde-linux-images.s3.kde.org/index.html#testing-buildstream/`.
- Issue [kde-linux#768](https://invent.kde.org/kde-linux/kde-linux/-/issues/768)
  by Aleix Pol (closed 2026-11-03) decides to stay on freedesktop-sdk 26.08.
- Merge request [kde-linux!667 "Move builds into buildstream"](https://invent.kde.org/kde-linux/kde-linux/-/merge_requests/667)
  merged into `buildstream` on 2026-11-18.
- The GitLab project `packaging/kde-buildstream` has the identifier 27077.
  KDE made the project on 2026-07-06. Its description is "Buildstream definitions
  for KDE software".

### 1.3 Maintainers and activity

| Repository and branch | Commits in the last 60 days | Authors |
|---|---|---|
| `packaging/kde-buildstream` `master` (139 commits in total) | 56 | Aleix Pol (38), KDE CI bot (10), Hadi Chokr (7), Silver Chokr (1) |
| `kde-linux/kde-linux-packages` `buildstream` | 38 | KDE CI bot, Hadi Chokr, Aleix Pol |
| `kde-linux/kde-linux` `buildstream` (commits not in `master`) | 35 | Harald Sitter, Aleix Pol, Sky Poincet, Tomaz Canabrava, Bhushan Shah |

Harald Sitter started all three projects. Aleix Pol does most of the work
now. A bot (`buildstream-servicing-bot`) opens a merge request for source
updates each few days. The last one is `kde-buildstream!76` (2026-11-24).

### 1.4 What the upstream builds, and how

| Topic | Finding | Evidence |
|---|---|---|
| Qt | 6.12.0, 39 elements, from release archives with the `anitya` source | `kde-buildstream:elements/qt/qtbase.bst` |
| KDE Frameworks, Plasma, Gear | Not BuildStream elements on `master`. One element runs kde-builder with `branch-group: latest-kf6`. Thus, it builds the Git `master` of each KDE module each night. | `kde-linux-packages:elements/kde-linux-payload.bst`, `kde-linux-packages:kde-builder.yaml.in` |
| KDE as elements | 165 generated `kde/` elements exist only on a work branch. The merge request is open. | `kde-buildstream!68` "Add KDE elements", branch `work/apol/gen-kde` (`3b63e60`); `kde-linux!670` (draft) |
| Sandbox | The payload element has the kind `manual-run-host`. This local plugin gives the build access to the host for ccache and logs. | `kde-linux-packages:plugins/elements/manual-run-host.py`, `kde-linux-packages:build.sh` |
| freedesktop-sdk changes | A patch queue of 4 patches: kernel, systemd, fwupd-efi and shim | `kde-buildstream:patches/freedesktop-sdk/` |
| gnome-build-meta | No junction now. The user configuration still names a `gnome` project. | `kde-buildstream:buildstream.conf.readable` |
| Image assembly | BuildStream makes the root file system, the initrd and the UKI. Then `build.sh` and mkosi assemble the image. | `kde-linux:build.sh`, `kde-linux:mkosi.conf` |
| Image format | An EROFS root image, a `caibx` index, a UKI and systemd-boot. No bootc. No composefs. No OCI image. | `kde-linux:build.sh` |
| Updates | systemd-sysupdate downloads the EROFS image and the UKI. The installed system uses btrfs for data. | `kde-linux:mkosi.extra/usr/lib/sysupdate.d/` |
| Initrd | dracut, in a `script` element | `kde-linux:elements/os/initrd.bst` |
| Installer | Calamares, in a live sysext on the ISO | `kde-linux:mkosi.extra/live/usr/calamares/` |
| CI | GitLab CI on KDE runners (`LargeVM`). One job runs `build.sh`. OpenQA tests the image, but the job can fail without an effect. | `kde-linux:.gitlab-ci.yml` (`allow_failure: true`) |
| Artifact cache | `https://buildstream.cache.kde-linux.haraldsitter.eu:11001`, plus proxy caches for freedesktop-sdk. The host is not on a KDE domain. | `kde-buildstream:project.conf` |
| Versions and releases | No tags. No releases. `master` moves each few days. | `git ls-remote --tags` gives 0 lines |
| Source updates | The project `sysadmin/buildstream-management` runs `bst source track` and opens a merge request | kde-linux#727 |
| Flatpak runtime | No Flatpak elements now. kde-linux#727 says that `kde-buildstream` will become the base of the KDE Flatpak runtime. A different merge request, `packaging/flatpak-kde-runtime!14`, moves that runtime to BuildStream. | `grep` for `flatpak_image` gives 0 elements |
| Plan for `kde-linux-packages` | kde-linux#727 says that this repository will go away when generated elements replace kde-builder | kde-linux#727 |
| Licence | Elements: BSD-2-Clause. Patches for freedesktop-sdk: MIT. The repository uses REUSE. | `kde-buildstream:REUSE.toml` |
| BuildStream version | `min-version: 2.5` in `project.conf`. CI installs BuildStream 2.7 or later. | `kde-buildstream:build.sh` |

### 1.5 The gates of ADR 0003, evaluated again

| Gate | Result on 2026-11-25 |
|---|---|
| 1. Complete graph for Plasma as elements | Not met on `master`. It is met on the work branch of `kde-buildstream!68`. |
| 2. Native BuildStream path for image and ISO, without mkosi | Not met. mkosi and `build.sh` do the final assembly. |
| 3. Bootable image, version policy, CI evidence | Partly met. Images of the `testing-buildstream` edition exist. There is no version policy. OpenQA does not gate the image. |

Conclusion: the upstream is real, official and active. It is not a
replacement for the Tromsø graph today. But two of its layers (`qt/` and
`components/`) are complete, and Tromsø can use them after a base update.

### 1.6 What the survey searched, and what it did not find

- The survey read the three repositories and the GitLab project data.
- It read the merge requests that match "buildstream".
- It read the text of kde-linux#727 and kde-linux#768.
- The survey did not read the 50 comments of kde-linux#727. The GitLab
  interface for comments needs an account.
- The survey did one search of the web, with two results. It read only their
  summaries in the search result.
  - A Phoronix article of 2026-10-02
    (<https://www.phoronix.com/news/BuildStream-Based-KDE-Linux>). The summary
    says that KDE has not yet decided to ship the BuildStream image.
  - Aleix Pol, "KDE Linux, BuildStream and Hope", FrOSCon 2026
    (<https://programm.froscon.org/froscon2026/talk/dbe55194-603c-4722-8573-75949ce6c8f6/>).
- The survey found no date for the change of the main line. kde-linux#727
  asks the question "when do we land it?" and gives no answer in its text.
- The survey did not examine the content of the artifact cache.

## 2. Tromsø compared with the KDE Linux BuildStream work

Tromsø data is from `main` at `bb04c75` (2026-11-25).

### 2.1 Junctions and base

| Item | Tromsø | KDE Linux upstream | Class |
|---|---|---|---|
| freedesktop-sdk | `freedesktop-sdk-26.08.4`, track `freedesktop-sdk-26.08*` (`elements/freedesktop-sdk.bst`) | `26.08.4-216`, track `release/26.08` | ALIGNED (step 4) |
| freedesktop-sdk patch queue | 2 files in `patches/freedesktop-sdk` | 4 patches | DIVERGED |
| Overrides of freedesktop-sdk | The `sdk/` targets point into `gnome-build-meta.bst`; local systemd and geoclue overrides remain | 1 override (`at-spi2-core`) | ALIGNED for SDK (step 5) |
| freedesktop-sdk-extra | Used only through the gnome-build-meta junction | Junction | BEHIND (step 8) |
| gnome-build-meta | Junction, `gnome-51` at `51.1-36-g8a89846`; `sdk/` and `sdk-deps/` come from it | No junction | ALIGNED (step 5) |
| `buildstream-plugins` | 2.8.0 (`elements/plugins/buildstream-plugins.bst`) | 2.8.0 | ALIGNED (step 3) |
| `buildstream-plugins-community` | 2.5.0 | A branch commit `cffa06e` | ALIGNED for the source kinds (step 3) |
| Project options | `arch`, `toolbox`, `x86_64_v3`, `channel` | `arch`, `minimal_vm` | DIVERGED |
| Fatal warnings | `unaliased-url`, `unstaged-files` | none | AHEAD |

### 2.2 Element groups

The table uses the name of each element file. An element is "the same" when
the two projects have a file with the same base name.

| Tromsø directory | Elements | Where the upstream gets the same software |
|---|---|---|
| `elements/kde/qt6` | 32 | 29 are in `kde-buildstream:elements/qt/`. Tromsø has 6.10.3. Upstream has 6.12.0. |
| `elements/kde/frameworks`, `elements/kde/plasma`, `elements/kde/apps` | 120 | 112 are in the generated `kde/` elements of `kde-buildstream!68`. None is on `master`. |
| `elements/kde/libs` | 17 | 9 are in `kde-buildstream:elements/components/` |
| `elements/kde-linux-deps` | 197 | 58 in `kde-buildstream`, 30 in freedesktop-sdk-extra, 13 in freedesktop-sdk 26.08, 42 only in gnome-build-meta, 54 only in Tromsø |
| `elements/core-deps` | 169 | 106 only in gnome-build-meta, 26 in freedesktop-sdk-extra, 22 in freedesktop-sdk 26.08, 9 in `kde-buildstream` |
| `elements/sdk` plus the former `sdk-deps` | 2 local | `sdk-deps` removed; only `gcr-3` and `librice` remain local. Everything else resolves through `gnome-build-meta.bst`. |
| `elements/core` | 62 | Copies of gnome-build-meta GNOME applications. 1 (`orca`) is in `kde-buildstream`. |
| `elements/kde-linux-system` | 70 | Copies of the `gnomeos/` directory of gnome-build-meta |
| `elements/oci` | 24 | No equivalent. Upstream has no OCI image. |
| `elements/tromso` | 22 | No equivalent |

### 2.3 Where Tromsø is AHEAD

| Item | Tromsø | Upstream |
|---|---|---|
| bootc and composefs | `elements/kde-linux-deps/bootc.bst` (v1.15.1), `elements/oci/integration/bootc-config.bst` | Not present. Upstream uses systemd-sysupdate and EROFS. |
| OCI image | `elements/oci/tromso.bst`, published as `ghcr.io/tuna-os/tromso` | Not present |
| Final assembly in BuildStream | The OCI image is a BuildStream artifact | mkosi and `build.sh` |
| KDE modules as elements | 120 elements with a real dependency graph | 1 element that runs kde-builder |
| Signed publication | cosign, `cosign.pub`, `.github/workflows/build-final.yml` | A signature for sysupdate only |
| Promotion and rollback | `.github/workflows/promote-stable.yml`, `.github/workflows/rollback-stable.yml` | One edition, no promotion |
| Install tests | `.github/workflows/test-luks-install.yml`, `.github/workflows/test-plain-install.yml` | OpenQA, not a gate |
| Live ISO | `.github/workflows/build-iso.yml`, `tromso/Containerfile` | mkosi and Calamares |
| Offline graph tests | `tests/pytest/test_source_aliases.py`, `tests/pytest/test_source_tracking_scope.py` | `kde-buildstream:tools/check-missing-deps.py` only |
| Plasma patches | 40 patch files for 17 KDE modules, for example `patches/plasma-workspace`, `patches/kscreenlocker` | No patches for KDE modules |
| Applications in the image | Elisa, Gwenview, Kate, KCalc, Okular, PySide6 | Flatpak for applications |
| NVIDIA, snapd and codec sysexts | Elements exist in `elements/kde-linux-system/nvidia-runtime` and `elements/kde-linux-system/snapd`. The image graph does not use them (section 2.7). | `kde-buildstream!62` is open for NVIDIA containers |

### 2.4 Where Tromsø is BEHIND

| Item | Tromsø | Upstream |
|---|---|---|
| freedesktop-sdk | 25.08.17 | 26.08.4-216 |
| Qt | 6.10.3 (`elements/kde/qt6/qt6-qtbase.bst`) | 6.12.0 |
| Qt WebEngine, Qt WebView, Qt Graphs, Qt gRPC | Not present | Present in `kde-buildstream:elements/qt/` |
| Source updates for KDE and Qt | Not tracked. `.github/workflows/track-bst-sources.yml` tracks only `elements/tromso`. The files in `elements/kde` last changed on 2026-07-20, and the refs are older. | A bot updates all elements each few days |
| KDE module versions | Git `master` from March 2026. The kwin ref `v6.5.90-429-g36a51bd` has the commit date 2026-03-26. | Git `master` each night |
| Session and login | SDDM (`elements/kde/plasma/sddm.bst`) | plasma-login-manager, plasma-setup, plasma-keyboard |
| KDE modules that Tromsø lacks | 52 names, for example discover, plasma-welcome, plasma-firewall, plasma-disks, kio-extras, kio-fuse, kwallet-pam, partitionmanager, print-manager, krdp, flatpak-kcm | In `kde-buildstream!68` |
| Components that Tromsø lacks | 108 names, for example dbus-broker, snapper, docker, tuned, ddcutil, libqalculate, sshfs, htop, ripgrep | In `kde-buildstream:elements/components/` |
| Leaf components with a newer version upstream | 68 of 109 shared names (22 are equal, 19 are not clear), for example freerdp 3.24.2 and 3.33.1, fastfetch 2.62.1 and 2.71.0, iw 5.19 and 6.17, android-tools 34.0.5 and 37.0.0 | |
| `buildstream-plugins` | 2.5.0 | 2.8.0 |
| Check for missing optional dependencies | Not present | `kde-buildstream:tools/check-missing-deps.py` |
| SBOM and CVE report | Not present | `kde-buildstream!12` (draft) |

### 2.5 Where the two DIVERGED

| Item | Tromsø | Upstream |
|---|---|---|
| Element names | `kde/qt6/qt6-qtbase.bst`, `kde/frameworks/kio.bst`, `kde-linux-deps/zsh.bst` | `qt/qtbase.bst`, `kde/kio.bst`, `components/zsh.bst` |
| KDE sources | `git_repo` with `track: master` and a git-describe ref | kde-builder now. Generated elements with a commit ref in `kde-buildstream!68`. |
| Qt sources | `tar` with a fixed URL | `anitya`, which finds new releases |
| KDE recipes | Written by hand. Patches make some dependencies optional. | Generated from KDE metadata by `utils/update_kde_element.py` |
| systemd | Local copy of the gnome-build-meta element (`elements/core-deps/systemd.bst`), 6 patches | Patch 2 of the freedesktop-sdk patch queue |
| Kernel | freedesktop-sdk kernel, local module certificate | Patch 1 of the patch queue changes the kernel configuration |
| Boot chain | bootc, composefs, systemd-boot, signed with local keys | UKI, systemd-boot, shim with a KDE SBAT entry |
| Initramfs | gnome-build-meta `generate-initramfs` scripts (`elements/kde-linux-system/generate-initramfs.bst`) | dracut |
| Updates | bootc with uupd (`elements/tromso/uupd.bst`) | systemd-sysupdate |
| Installer | tuna-installer with the fisherman backend | Calamares |
| GNOME software | Local copies of 62 GNOME core elements. Most are not in the image. | Only orca |
| WebKitGTK | `gnome-build-meta.bst:sdk/webkitgtk-6.0.bst` at 2.54.1. The former local backport from #427 is gone. | Not present. Upstream uses Qt WebEngine |
| Installer provenance | [tuna-os/tromso#402](https://github.com/tuna-os/tromso/pull/402) pins the vendored proto-installer to gnome-build-meta `f26d7fc` | Not applicable |
| Name clash | The directories `kde-linux-deps` and `kde-linux-system` are copies of `gnomeos-deps` and `gnomeos` of gnome-build-meta. They are not from KDE Linux. | The upstream names are `components` and `os` |

### 2.5.1 PySide6 temporarily omitted from the image

PySide6 is not in the image graph. The `qt6-pyside6` build-dependency was
removed from `kde/frameworks/kcoreaddons.bst` and
`kde/frameworks/kwidgetsaddons.bst`; both already build with
`BUILD_PYTHON_BINDINGS=OFF`, so the bindings were not needed at build time.

Why: shiboken 6.10.3 mis-resolves nested enums and qflags typedefs against Qt
6.10.3 (`QDirListing`/`QDirIterator`, `QStringConverter`/`QCommandLineOption`,
`QLocalSocket`/`QLocalServer`, and others). The generated wrappers do not
compile. Qt’s headers are unchanged between 6.10.2 and 6.10.3, the PySide6
typesystem still has the same blocks in 6.11.0, 6.12.0 and `dev`, and a safe
generator fix was not available.

The `kde/qt6/qt6-pyside6.bst` element is retained. Re-add it to the two
framework build-depends when upstream shiboken/PySide6 is fixed, or when the
Qt/PySide6 stack is upgraded together. Verify by building
`kde/qt6/qt6-pyside6.bst` and then the full image.
See [tuna-os/tromso#222](https://github.com/tuna-os/tromso/issues/222).

### 2.6 Origin of the vendored gnome-build-meta copies

Tromsø has no record of the gnome-build-meta revision of its copies. The
survey compared the Git blob of each local file with gnome-build-meta.

- The best match on the `gnome-50` history is commit `37fb5a8`
  (2026-03-18). 201 of 600 mapped files are identical.
- 249 mapped files have different content. 150 mapped files do not exist in
  that commit.
Thus, the copies came from gnome-build-meta near March 2026. They have
drifted for 8 months. Step 5 removed the `elements/sdk` copies and the
`sdk-deps` directory; the remaining local GNOME elements still predate the
junction and move in later steps.

This drift is the cause of the work in #427 and #402. A junction removes it.

### 2.7 Local elements and the image graph

`bst show --deps all oci/tromso.bst` on the step 5 branch lists 1252
elements: 741 in the freedesktop-sdk junction, 96 in the gnome-build-meta
junction and 415 local. The repository has 732 local elements. Thus, 317
local elements are not in the image.

| Directory | In the image graph | In the repository |
|---|---|---|
| `elements/kde` (Qt, Frameworks, Plasma, applications, libraries) | 170 | 176 |
| `elements/kde-linux-deps` | 159 | 197 |
| `elements/sdk` plus the former `sdk-deps` | 2 | 2 |
| `elements/core-deps` | 47 | 169 |
| `elements/oci` | 22 | 24 |
| `elements/tromso` | 17 | 22 |
| `elements/kde-linux-system` | 10 | 70 |
| `elements/core` | 1 | 61 |

Findings:

- `elements/core` has 60 GNOME elements that the image does not use. Only
  `elements/core/sysprof-app.bst` is in the graph.
- 60 of 70 elements in `elements/kde-linux-system` are not in the graph. This
  includes the sysext images and `elements/kde-linux-system/signed-boot.bst`.
- `gnome-build-meta.bst:sdk/webkitgtk-6.0.bst` now supplies WebKitGTK 2.54.1
  in the Plasma image; the former local backport is gone.
- The SDK layer now has 96 elements from `gnome-build-meta.bst`; only the two
  Tromsø-only elements `sdk/gcr-3` and `sdk/librice` remain local.
- `elements/tromso/uupd.bst` is not in the graph. The survey did not find how
  the image gets uupd.

## 3. Tromsø compared with Dakota

Dakota data is from the `testing` branch at `91e2a21` (2026-11-25). Dakota had
109 commits in the last 60 days.

### 3.1 Structure

| Item | Dakota | Tromsø | Class |
|---|---|---|---|
| freedesktop-sdk | `freedesktop-sdk-26.08.4`, track `freedesktop-sdk-26.08*` | 25.08.17 | BEHIND |
| gnome-build-meta | Junction, track `gnome-51`, ref `51.1-36-g8a89846`, with a patch queue of 3 patches | Same junction and ref; Dakota's patch queue is not carried yet | DIVERGED (patches) |
| Local elements | 189 | 732 | DIVERGED |
| Overrides of freedesktop-sdk | They point into the gnome-build-meta junction | They point into the same junction for `sdk/`; local systemd and geoclue remain | DIVERGED (systemd) |
| Kernel choice | An override at the junction (`dakota:elements/core/linux-fdsdk.bst`) | freedesktop-sdk default | BEHIND |
| bootc | v1.17.3, a local override of the gnome-build-meta element | v1.15.1 (`elements/kde-linux-deps/bootc.bst`) | BEHIND |
| `buildstream-plugins` | 2.8.0 | 2.8.0 | ALIGNED |
| `buildstream-plugins-community` | 2.4.0 | 2.5.0 | AHEAD (`anitya` and all gnome-51 source kinds) |
| x86_64_v3 | On by default | Off by default | DIVERGED |

### 3.2 Boot security

| Item | Dakota | Tromsø | Class |
|---|---|---|---|
| Secure Boot signing | Option `secure_boot_signing`. `dakota:elements/bluefin/signed-modules.bst` signs the kernel, modules, systemd-boot and fwupd. | Copies of the gnome-build-meta elements, for example `elements/kde-linux-system/signed-boot.bst`. The work is in [tuna-os/tromso#516](https://github.com/tuna-os/tromso/issues/516). | BEHIND |
| Signing key safety | Signing runs in a separate job with no push to the cache | Not examined | Unknown |
| kexec | `dakota:elements/bluefin/kexec-disable.bst` sets `kernel.kexec_load_disabled = 1` | Not present | BEHIND |
| Kernel lockdown | `dakota:elements/bluefin/lockdown-kargs.bst` adds `lockdown=integrity` for signed images | Not present | BEHIND |
| Boot layer checks | `dakota:include/boot-layer.yml` makes sure that there is one kernel and that depmod ran | Not present | BEHIND |

### 3.3 Updates, image layout, CI and cache

| Item | Dakota | Tromsø | Class |
|---|---|---|---|
| uupd | Binary release v1.5.5 (`dakota:elements/bluefin/uupd.bst`) | Built from source, v1.5.9 (`elements/tromso/uupd.bst`) | AHEAD |
| sysext | `dakota:elements/bluefin/deps.bst` and a brew toolchain layer | NVIDIA, snapd, codecs and devel sysext images | DIVERGED |
| OCI layers | chunkah layers with an ownership plugin (`dakota:plugins/chunkah-ownership.py`) | Layers in `elements/oci/layers` | DIVERGED |
| Build | Remote execution on `cache.projectbluefin.io`, 4 image variants | Multi-runner chunks on GitHub runners, 1 variant | DIVERGED |
| Artifact cache | `https://gbm.gnome.org:11003` and `https://cache.projectbluefin.io:11001` | `https://cache.freedesktop-sdk.io:11001`, plus zstd archives of the CAS on GHCR | DIVERGED |
| CI configuration | `dakota:.github/actions/generate-bst-ci-config` | The same action, an older copy | Shared |
| Source tracking | `track-bst-sources.yml` and `track-next-junctions.yml`. A `next` branch tests junction updates. | `track-bst-sources.yml` for `elements/tromso` only. No `next` branch. | BEHIND |
| Publication | Separate `publish.yml` with signature, attestation and SBOM | `.github/workflows/build-final.yml` with cosign | BEHIND (SBOM) |
| Vulnerability scan | `vulnerability-scan.yml` | Not present | BEHIND |
| aarch64 | Manual workflow | Not present | BEHIND |
| Install tests | `e2e.yml`, manual | LUKS and plain install tests on each build | AHEAD |
| Live ISO | In `projectbluefin/dakota-iso` | In this repository | DIVERGED |
| Patch check | `dakota:patches/freedesktop-sdk.manifest.json` and `just patch-sync` | Not present | BEHIND |

### 3.4 What Tromsø must share with Dakota

1. The same freedesktop-sdk release line (26.08).
2. A gnome-build-meta junction on the same branch (`gnome-51`). The junction
   supplies systemd, bootc, the initramfs scripts, the Secure Boot elements
   and the `sdk/` overrides.
3. The same Secure Boot option name (`secure_boot_signing`) and the same
   element names for signed modules.
4. The `kexec-disable` and `lockdown-kargs` elements.
5. The same plugin versions.
6. A `next` branch, or an equal procedure, to test junction updates.

## 4. Target structure

### 4.1 Options

| Option | Description | Result |
|---|---|---|
| A. One junction to `kde-linux` | Use the full upstream chain | Rejected. The chain has no bootc, no OCI image and needs mkosi. |
| B. Periodic copy of elements | Keep all elements local. Copy changes by hand or by script. | Rejected as the target. This is the present state. It caused the drift in section 2.6. |
| C. Layered junctions | Junction each upstream for the layer that it owns. Keep only Tromsø elements local. | Recommended |

### 4.2 Recommended structure (option C)

```text
tromso (this repository)
├── freedesktop-sdk.bst          26.08, one patch queue
├── freedesktop-sdk-extra.bst    leaf components
├── gnome-build-meta.bst         gnome-51: systemd, bootc, boot chain, sdk overrides
├── kde-buildstream.bst          qt/ and components/ now, kde/ after !68
└── local elements
    ├── tromso/                  Aurora layer, branding, uupd, brew
    ├── oci/                     OCI image and layers
    ├── kde/                     only until kde-buildstream has kde/ on master
    └── overrides/               elements that replace an upstream element
```

Rules:

- Each junction overrides the nested `freedesktop-sdk.bst` with the junction
  of Tromsø. Thus, the image has one base.
- A local element replaces an upstream element only through a junction
  override. Each override has a comment with the reason and the condition
  for its removal.
- Local patches for KDE modules stay local. Each patch gets a note: send
  upstream, or keep.

### 4.3 Trade-offs

| Topic | Layered junctions (C) | Periodic copy (B) |
|---|---|---|
| Rebuild cost | An update of the Qt ref rebuilds all KDE elements (about 6 hours of chunk jobs). The same is true today. | The same |
| Cache | The upstream cache will not match. Tromsø overrides systemd, and Qt depends on it. Each cache key is then different. This is not verified. | No upstream cache |
| Patch carrying | Patches for an element in a junction need a patch queue on the junction, or a local override. This is more work for each patch. | A patch is one line in a local element |
| Cadence | `kde-buildstream` has no releases. Tromsø pins a commit and moves the pin on a schedule. A bad upstream commit stays out until the pin moves. | Tromsø controls each ref |
| Review load | One junction update changes many elements at one time. It needs a full build and a boot proof. | Many small updates |
| Local elements | About 150 after the migration (an estimate) | 801, of which 499 are in the image |
| What users see | Newer Qt and Plasma. The KDE Linux default applications and settings can show through. Tromsø keeps SDDM or moves to plasma-login-manager by decision. | No change |
| Risk of upstream change | The upstream can rename or remove elements. The pin protects the build. | None |

### 4.4 What stays local on purpose

- bootc, composefs and the OCI image (`elements/oci`). The upstream has a
  different update model.
- The Aurora layer and the brand files (`elements/tromso`).
- The installer (tuna-installer and fisherman), the live ISO and the install
  tests.
- Signatures, promotion and rollback.
- The sysext images for NVIDIA, snapd and codecs.
- Applications in the image, if the owner keeps them.

## 5. Ordered steps

Each step is one pull request. Each step that changes the image needs a green
CI build and a boot proof (the live ISO gate and the install tests).

| Step | Change | Changes the image | Proof |
|---|---|---|---|
| 0 ([#522](https://github.com/tuna-os/tromso/pull/522)) | This document and the tracking issue | No | Linters |
| 1 ([#524](https://github.com/tuna-os/tromso/pull/524)) | Add `kde-buildstream` as a pinned junction that no element uses | No | The cache keys of `oci/tromso.bst` do not change |
| 2 ([#525](https://github.com/tuna-os/tromso/issues/525)) | Start source tracking again for `elements/kde/frameworks`. Plasma `master` needs Qt 6.11 (see the order rules), so Plasma and applications wait for step 11. | Yes | Full build, boot proof |
| 3 ([#526](https://github.com/tuna-os/tromso/issues/526)) | Update `buildstream-plugins` to 2.8.0 and `buildstream-plugins-community` to the version that `kde-buildstream` needs | Probably all cache keys. Measure with the key list. | Full build, boot proof |
| 4 ([#527](https://github.com/tuna-os/tromso/issues/527)) | Move freedesktop-sdk to 26.08. Rebase the patch queue. | Yes (full rebuild) | Full build, boot proof, install tests |
| 5 ([#528](https://github.com/tuna-os/tromso/issues/528)) | Add a gnome-build-meta junction (`gnome-51`). Replace `elements/sdk` and the former `sdk-deps` with references into the junction. | Yes | Full build, boot proof |
| 6 ([#529](https://github.com/tuna-os/tromso/issues/529)) | Replace `elements/core-deps` and the boot elements in `elements/kde-linux-system` with the junction. Take bootc from the Dakota override. | Yes | Boot proof, install tests, Secure Boot test |
| 7 ([#530](https://github.com/tuna-os/tromso/issues/530)) | Remove the 60 elements of `elements/core` and the other 242 local elements that the image graph does not use | No, if the graph is equal | Cache key comparison |
| 8 ([#531](https://github.com/tuna-os/tromso/issues/531)) | Add a freedesktop-sdk-extra junction. Remove the 60 local copies. | Yes | Full build, boot proof |
| 9 ([#532](https://github.com/tuna-os/tromso/issues/532)) | Take `kexec-disable`, `lockdown-kargs` and the boot layer checks from Dakota | Yes | Boot proof, Secure Boot test |
| 10 ([#533](https://github.com/tuna-os/tromso/issues/533)) | Switch leaf components to `kde-buildstream.bst:components/`, in groups of about 20 | Yes | Full build, boot proof |
| 11 ([#534](https://github.com/tuna-os/tromso/issues/534)) | Switch Qt to `kde-buildstream.bst:qt/` (6.12) | Yes (all KDE elements) | Full build, boot proof, session test |
| 12 ([#535](https://github.com/tuna-os/tromso/issues/535)) | After `kde-buildstream!68` merges: switch Frameworks, then Plasma, then applications to `kde-buildstream.bst:kde/` | Yes | Full build, boot proof, session test |
| 13 ([#536](https://github.com/tuna-os/tromso/issues/536)) | Rename or remove `kde-linux-deps` and `kde-linux-system` | Probably yes. Measure with the key list. | Full build |
| 14 ([#537](https://github.com/tuna-os/tromso/issues/537)) | Add junction tracking with review, and a `next` branch | No | CI |

Status of step 1 ([tuna-os/tromso#524](https://github.com/tuna-os/tromso/pull/524)):

- The junction is `kde-buildstream.bst`, pinned at `ee0596e`.
- The list of names and cache keys of `oci/tromso.bst` has 1216 lines. It is
  identical on `main` and on the branch.
- At step 1, a trial target did not resolve. BuildStream fetched the upstream
  project and its freedesktop-sdk 26.08 junction, and the patch queue
  applies. Then BuildStream stops, because two projects load
  `buildstream-plugins-community` at different versions.
- Step 3 is applied in this branch: `buildstream-plugins` is 2.8.0 and
  `buildstream-plugins-community` is 2.5.0. Version 2.5.0 has every source
  kind the gnome-51 and kde-buildstream project files list, including
  `anitya` and `go_mod_vendor`.

A local hazard, found in step 1: `pytest` writes `__pycache__` into
`files/kde-linux-system/generate-initramfs`. That directory is a `local`
source. Thus, 11 cache keys change in a local checkout after a test run. CI
does not have this problem. Remove the directory before a local build.

Status of step 5 ([tuna-os/tromso#528](https://github.com/tuna-os/tromso/issues/528)):

- `elements/gnome-build-meta.bst` pins `gnome-51` at
  `51.1-36-g8a89846df11e86cee57c728a86a247e61d604b84`.
- `elements/sdk` keeps only `gcr-3` and `librice`; the former `sdk-deps`
  directory is removed. Every other `sdk/` and `sdk-deps/` reference points
  into the junction.
- The freedesktop-sdk `sdk/` overrides, including `krb5`, `glycin` and
  `libglycin`, point into the junction. The local `krb5` element and its C23
  failure are gone.
- `buildstream-plugins` 2.8.0 and `buildstream-plugins-community` 2.5.0 are
  required to load the gnome-51 project (step 3).
- `bst show --deps all oci/tromso.bst` resolves 1252 elements, 96 of them
  from `gnome-build-meta.bst`.
- `gnome-build-meta.bst:sdk/krb5.bst` builds or pulls successfully.
- The full image build and boot proof are not yet available.
- A full build on 2026-11-27 built 75 elements and used 719 cached elements.
  It failed on `core-deps/xvfb.bst` and
  `gnome-build-meta.bst:sdk/webkitgtk-6.0.bst`.
- The first shell failures were on local `kind: manual` elements. The
  freedesktop-sdk update removed `sh` from the `runtime-minimal` build
  environment. The branch adds `runtime-gnu` to the build dependencies of
  every local manual element.
- `signed-modules` also copied `/boot/vmlinuz`, which the kernel element
  does not install. The branch copies
  `/usr/lib/modules/${version}/vmlinuz` instead.
- `protobuf-c` needs the protobuf and abseil devel headers. It also needs
  `-std=c++20` for the abseil headers.
- `core-deps/xvfb.bst` fails with `nettle/sha.h: No such file or directory`.
  The `gnome-51` nettle artifact has no headers. A patch for xserver or a
  nettle 3.x element is needed.
- `webkitgtk-6.0` reaches the 2-hour remote build timeout. An earlier try
  failed with `ninja: fatal: pipe: Too many open files`. The step needs a
  longer remote timeout, a faster worker, or a seeded artifact.
- The draft pull request records these build observations. The image and
  boot proof remain open.

Order rules:

- `plasma/kwin` and `plasma/plasma-workspace` on `master` set
  `QT_MIN_VERSION` to 6.11.0. Tromsø has Qt 6.10.3. `frameworks/kio` needs
  only 6.10.0. Thus, step 2 can update Frameworks, but not Plasma.

- Steps 3 and 4 probably each cause a full rebuild. Do not combine them with other
  changes.
- Step 4 comes before steps 5, 8, 10 and 11. All three upstreams are on
  26.08. Their elements depend on elements that freedesktop-sdk 25.08 does
  not have.
- Step 12 has an external condition. Do not wait for it. Steps 2 to 11 have
  value without it.

## 6. What to send upstream

The agent does not post to `invent.kde.org`, GitLab or Project Bluefin. The
owner sends each item. Drafts are in `docs/outreach`.

| Item | Target | Draft |
|---|---|---|
| Introduction of Tromsø as a consumer, and a request for tags or a stable branch | `packaging/kde-buildstream` | [draft](outreach/kde-buildstream-consumer-intro-draft.md) |
| A request to keep the nested `freedesktop-sdk.bst` junction easy to override | `packaging/kde-buildstream` | In the same draft |
| Patches that make KDE dependencies optional (`patches/plasma-workspace`, `patches/spectacle`) | The KDE modules | To write, one for each module |
| Elements that only Tromsø has (54 in `elements/kde-linux-deps`), where the upstream wants them | `packaging/kde-buildstream` | To write after step 10 |
| bootc as a second image backend | `kde-linux/kde-linux` | Do not send now. The upstream chose systemd-sysupdate. |

## 7. Risks

| Risk | Effect | Control |
|---|---|---|
| `kde-buildstream!68` does not merge, or changes shape | Step 12 stops | Steps 2 to 11 do not depend on it. Keep local `elements/kde`. |
| The upstream has no releases | A pin update can break the build | Pin a commit. Test updates on a `next` branch. |
| The upstream cache host is a personal domain | The cache can stop | Do not depend on it. Use the Tromsø cache. |
| freedesktop-sdk 26.08 changes the base ABI | Regressions in the image | One step, full install tests, stable promotion gate |
| gnome-build-meta `gnome-51` elements do not fit a Plasma image | Build failures in steps 5 and 6 | Dakota shows the pattern. Use overrides. |
| The upstream patch queue changes the kernel and systemd for KDE Linux | Conflict with bootc needs | Tromsø overrides the nested junction. The upstream queue is then not applied. |
| Full rebuilds use many runner hours | Slow steps | One full-rebuild change in each pull request |
| Other work in progress (installer, Secure Boot, ORAS cache) touches the same files | Merge conflicts | Steps 5, 6 and 9 start after [tuna-os/tromso#516](https://github.com/tuna-os/tromso/issues/516) settles |

## 8. Not verified

- No BuildStream build of the upstream chain was run.
- Section 4.3 says that Tromsø cannot use the upstream cache. This is an
  inference. No test confirms it.
- The element comparison uses file names. Two elements with the same name
  can build different options. Two elements with different names can build
  the same software.
- The version comparison reads the first source of each element.
- The count of gnome-build-meta copies (about 290) uses the `gnome-51`
  branch for names and the `gnome-50` history for content.
- The survey read the commit date of the kwin ref only. It did not read
  the dates of the other KDE refs.
- The CI workflows that build the image do not run `pytest`. The survey
  confirmed this with a search of the workflow files only.
- The survey did not test that an update of the plugins changes all cache
  keys.
