# The OGC variant

Issue: [#550](https://github.com/tuna-os/tromso/issues/550). Image:
`ghcr.io/tuna-os/tromso-ogc`, x86_64 only.

The variant is Tromsø with the kernel of the
[Open Gaming Collective](https://github.com/OpenGamingCollective) (OGC) and the
gaming parts of [Bazzite](https://github.com/ublue-os/bazzite). This page has
the design, the inventory of Bazzite, and the limits.

## How the variant works

The project option `flavor` has two values, `main` and `ogc`. The default is
`main`. The option has no `variable:`, so it enters a cache key only where a
conditional uses it.

| Place | What `flavor=ogc` changes |
|---|---|
| `elements/freedesktop-sdk.bst` | The override of `components/linux.bst`, and one more patch queue (`patches/freedesktop-sdk-ogc`) |
| `elements/oci/layers/tromso-stack.bst` | One more dependency, `ogc/deps.bst` |
| `elements/oci/os-release.bst`, `elements/oci/tromso.bst` | The name of the image |

**Proof that the default image does not change.** `bst show` gave the same 1252
full cache keys for `oci/tromso.bst` on `main` and on this branch. The check was
on 2026-11-26, with `main` at d36f715 (freedesktop-sdk 26.08.4). An equal cache key is the same inputs, so it is the same artifact.
With `-o flavor ogc`, 46 elements have a new key. To repeat the check:

```bash
BST_FLAGS="--no-interactive" just bst show --deps all \
  --format "'%{name} %{full-key}'" oci/tromso.bst | sort
```

**CI.** `build-tromso-ogc.yml` is a separate workflow with a separate schedule.
It reads the CAS caches of the default build and does not write them. It calls
`build-final.yml`. So the variant has the same layers, lint and scan. It has the
same whiteout and capability checks, and the same Secure Boot layer.

`scripts/check-ogc-image.py` then checks the variant against
`files/ogc/manifest.json`. In a pull request the label `build-ogc-image` starts
the image build. A pull request never publishes.

## The kernel

### Route

The kernel is built from source in BuildStream (`ogc/linux.bst`). The signed OCI
packages of OGC are not used:

1. `AGENTS.md` and `docs/MAINTAINING.md` do not accept a pre-built binary in
   place of a source build.
2. The packages are Fedora RPMs. Their modules have signatures from the keys of
   the OGC build and, in Bazzite, of Universal Blue. The tunaOS key cannot
   replace those keys in the kernel.
3. Tromsø changes the configuration (composefs boot path, zstd modules).

The OCI package has one use: the `.config` in it is the base configuration.

| Input | Pin | Check on 2026-11-25 |
|---|---|---|
| `linux-7.3.5.tar.xz` (kernel.org) | SHA-256 `8f293f83…` | Good signature, `647F28654894E3BD457199BE38DBBDC86092693E` |
| `monolithic.patch` of `v7.3.5-ogc3` | SHA-256 `53a70c95…`; tag commit `7522e30f51f9197673eb7f771a6b841673c5af36` | Good signature, `5D14C1B29026A9366B2EB4322B440F6473435C1A` |
| `kernel-packages-fedora:7.3.5-ogc3.1-fc45` (for `.config` only) | `sha256:cc529ae6cfc91df2a078b9efca1df55134440325f8038a64c548f0a761e4f2ec` | `cosign verify` passes, keyless, identity below `github.com/OpenGamingCollective/kernel-packages` |
| `ogc.config.set`, `ogc.config.unset` | kernel-packages `cd80e50c8944fb11ef4377381b092c54b06dc729` | Byte-for-byte copies |

Bazzite names this kernel in `build.py` (`7.3.5-ogc3.1.fc45`, commit
`b42cdec64f91b8218ff710724099cce6245805e0`, 2026-11-24). The value 7.0.9 in its
`Containerfile` is an old default.

### Configuration

`files/ogc/kernel/merge-config.sh` composes the configuration: the Bazzite
`.config`, then options that only the default Tromsø kernel has, then the OGC
fragments, then the Tromsø policy. After `olddefconfig` it fails if a policy
line is not exact, or if an option that Bazzite or the Tromsø fragment enables
is lost. `allow-missing.txt` has the exceptions with their reasons.

### Modules and signatures

One element builds the kernel and the out-of-tree modules. A new RSA key for each
build signs all modules. The key is in the tmpfs of the sandbox, not in the build
tree, and the build deletes it. The build fails if `/tmp` is not a tmpfs, if one
module has no signature, or if a private key is in the artifact.

The kernel trusts that key only. It does not trust the development keys in
`files/boot-keys`, which are public. The price is that two builds of this element
are not identical. A new version of one module builds the kernel again.

### Secure Boot and lockdown

- BuildStream does not sign `vmlinuz`. The publish job signs it with the tunaOS
  key, as for the default image (`docs/secure-boot.md`). No key of OGC or of
  Universal Blue is in the chain.
- With Secure Boot on, `IMA_ARCH_POLICY` makes the signature of each module
  mandatory. The modules of this image have them. The lockdown LSM is in the
  kernel and in the LSM list.
- The default image is different: its kernel has `IMA_ARCH_POLICY=y` and
  `MODULE_SIG` off (read from `tromso:latest` of 2026-10-15). With Secure Boot
  on, that kernel can refuse its own modules: `ima_efi.c` then adds the rule
  `appraise func=MODULE_CHECK appraise_type=imasig`. No test has shown it.
- `ryzen_smu` gives raw access to the registers of the SMU, so it makes a hole in
  lockdown. It is not in the image. `wl` is also not in the image (licence).

### Filesystem

The kernel is older than 7.4-rc2, which has the btrfs fs-verity fix. So the
composefs root is **ext4**, as for `tromso:kde` in `tunaos.toml` of
tuna-os/tunaOS. When OGC moves to 7.4, change the row of the cell, not before.

### To move the version

1. Read `build.py` of Bazzite for the version of its stable channel.
2. Download the tarball, the patch and the two signatures. Check them with the
   two fingerprints above.
3. Change the two hashes in `ogc/linux.bst` and the version in its
   `cpe` block, `kernel_release` in `files/ogc/manifest.json`, and
   `CONFIG_LOCALVERSION` in `tromso-policy.config`.
4. Extract the new `.config` from the verified OCI package.
5. Open a pull request. The kernel job tests all modules.

## Inventory

Sources: Bazzite `b42cdec64f91b8218ff710724099cce6245805e0` (`build_files`,
`system_files`), ublue-os/akmods `921aba95c65765f18f8b4fd63ee5a5443673b49a`, and
terrapkg/packages `054ef9bcfbdca65444744ff70b30fa7ef4ecf193` for the packages that
Bazzite installs.

Scope: **D** desktop, **H** handheld (`bazzite-deck`), **N** NVIDIA. "In Tromsø"
means in the default image.

### Kernel and modules

| Bit | Source | Scope | In Tromsø | Taken | Form | Licence | Reason when skipped |
|---|---|---|---|---|---|---|---|
| OGC kernel 7.3.5-ogc3: handheld HID drivers, Steam Deck, Steam Machine, ASUS, Lenovo, MSI, AYANEO, OneXPlayer, Zotac, `vram-overcommit`, dmem cgroups, VRR, `CONFIG_NTSYNC`, sched_ext | OpenGamingCollective/linux | D H | no | yes | kernel, `ogc/linux.bst` | GPL-2.0 | |
| `xone_dongle` `xone_gip` `xone_gip_gamepad` `xone_gip_headset` `xone_gip_chatpad` `xone_gip_madcatz_strat` `xone_gip_madcatz_glam` `xone_gip_pdp_jaguar` | OpenGamingCollective/xonedo 982cbcb | D | no | yes | module | GPL-2.0 | The firmware of the wireless dongle is not in the image: Microsoft gives no right to redistribute it. Cable and Bluetooth need no firmware. |
| `razerkbd` `razermouse` `razerkraken` `razeraccessory` | openrazer v3.12.4 | D | daemon only | yes | module | GPL-2.0 | |
| `v4l2loopback` | v4l2loopback v0.15.4 | D | no | yes | module | GPL-2.0 | |
| `kvmfr` | gnif/LookingGlass 1b48530 | D | no | yes | module | GPL-2.0 | |
| `zenergy` | BoukeHaarsma23/zenergy 2a40d24 | D | no | yes | module | GPL-2.0 | The build changes the mode of the counters from 0444 to 0400 (PLATYPUS, CVE-2020-12912). |
| `nct6687` | Fred78290/nct6687d 3e48610 | D | no | yes | module | GPL-2.0 | |
| `gcadapter_oc` | HannesMann/gcadapter-oc-kmod 0a7d702 | D | no | yes | module | GPL-2.0 | |
| `evdi` | DisplayLink/evdi 5174804 | D | no | yes | module | GPL-2.0 | The DisplayLink daemon is proprietary and is not in Bazzite either. |
| `hid-logitech-new` | berarma/new-lg4ff 2092db1 | D | no | yes | module | GPL-2.0 | |
| `hid-tmff-new` `hid-tminit-new` `usb-tminit-new` | Kimplul/hid-tmff2 7a1274d | D | no | yes | module | GPL-2.0 | |
| `hid-t150` | scarburato/t150_driver f7ecb30 | D | no | yes | module | GPL-2.0 | |
| `hid-fanatec` | gotzl/hid-fanatecff 13340fc | D | no | yes | module | GPL-2.0 | |
| `hid-logitech-dd` | mescon/logitech-trueforce v0.43.3 | D | no | yes | module | GPL-2.0 | |
| `hid-hori` | LinuxGamesTV/hori_control_systems 0.0.8 | D | no | yes | module | GPL-2.0 | |
| `sc0710` | Nakildias/sc0710 60753c5 | D | no | yes | module | GPL-2.0 | |
| `system76` `clevo-acpi` `system76-io` `system76-thelio-io` | pop-os/system76-dkms 90ea5e6, system76-io-dkms fc71f15 | D | no | yes | module | GPL-2.0 | |
| `vhba` | cdemu vhba-module 20260313 | D | no | yes | module | GPL-2.0 | |
| `ayaneo-platform` `ayaneo-leds` | ShadowBlip v0.3.5, TiPSilva 0be120d | H | no | yes | module | GPL-2.0 | |
| `ryzen_smu` | amkillam/ryzen_smu d298366 | D H | no | **no** | module | GPL-2.0 | Security: raw SMN register writes from sysfs, a hole in lockdown |
| `wl` (broadcom-wl) | Broadcom 6.30.223.271 | D | no | **no** | module | proprietary | Licence: "Redistributable, no modification permitted", and a closed binary |
| NVIDIA open module and driver | akmods-nvidia-open | N | elements exist, not in the image | **no** | module | MIT/GPL and proprietary | The NVIDIA image of Bazzite is a different image. The Tromsø NVIDIA elements are for sysext, which bootc does not use. |
| `bazzite-firmware-nonfree` | submodule `firmware` | D H | no | **no** | firmware | none stated | Licence: the repository states none |

### Graphics and audio patches

| Bit | Source | Scope | In Tromsø | Taken | Form | Licence | Reason when skipped |
|---|---|---|---|---|---|---|---|
| Mesa: frame limiter, RADV default, `vram-overcommit` | OpenGamingCollective/mesa 0a865f5 | D H | no | yes | patch on Mesa 26.2.5 | MIT | |
| WirePlumber: no `clear-default` from Steam | OpenGamingCollective/wireplumber 3a9ba0b | D H | no | yes | patch on 0.5.18 | MIT | |
| Xwayland: Valve patches (3) | terrapkg 054ef9b | D H | no | yes | patch on 24.1.14 | MIT | |
| BlueZ: Valve patches (7) | terrapkg 054ef9b | D H | no | **no** | patch | GPL-2.0 | Technical: `bluez-libs` is below PipeWire, so a new key builds most of the desktop again. The test hardware is not available. Follow-up. |
| gamescope 3.17.0-ogc1 and its WSI layer | OpenGamingCollective/gamescope 4246b87 | D H | no | yes | package, `ogc/gamescope.bst`, `ogc/luajit.bst`, `ogc/libxres.bst` | BSD-2-Clause | Without OpenVR: it needs the closed SteamVR runtime |
| MangoHud 0.8.4 with mangoapp | flightlessmango/MangoHud | D H | no | yes | package, `ogc/mangohud.bst`, `ogc/glfw.bst`, `ogc/nlohmann-json.bst` | MIT | Without mangoplot: no matplotlib in the image |
| vkBasalt 0.3.2.9 | DadSchoorse/vkBasalt | D | no | yes | package, `ogc/vkbasalt.bst` | Zlib | |
| ScopeBuddy | OpenGamingCollective/ScopeBuddy 44ab54e | D | no | yes | package, `ogc/scopebuddy.bst` | Apache-2.0 | |
| vulkan-low-latency-layer | terrapkg 054ef9b | D | no | **no** | package | MIT | Follow-up |
| 32-bit libraries (Mesa, vkBasalt, MangoHud, gamescope WSI) | Terra i686 | D H | no | **no** | package | | Technical: the freedesktop-sdk junction builds x86_64 only. The Flatpak runtimes of Steam have their 32-bit Mesa, and the variant preinstalls the MangoHud and gamescope layers for Flatpak. |
| OpenH264, libfreeaptx, intel-opencl, ROCm | Fedora, negativo17, Cisco | D | no | **no** | package | mixed | Licence for the first two (patents, Cisco binary). Technical for ROCm: about 60 packages with a fork of LLVM. |
| OBS vkcapture, OpenXR loader, libFAudio | Fedora | D | no | **no** | package | | The Flatpaks of OBS, Steam and Lutris contain them |

### Sessions, launchers and tools

| Bit | Source | Scope | In Tromsø | Taken | Form | Licence | Reason when skipped |
|---|---|---|---|---|---|---|---|
| Steam, Lutris, Protontricks, ProtonPlus, Heroic | RPM or Flatpak in Bazzite | D | no | yes | Flatpak preinstall, `ogc/config.bst` | Steam is proprietary | Native Steam needs 32-bit userspace |
| umu-launcher, winetricks | Terra | D | no | **no** | package | GPL-3.0, LGPL | The Flatpaks of Lutris and Heroic contain them |
| extest, `bazzite-steam`, `bazzite-steam-bpm` | Bazzite | D | no | **no** | config | | For native Steam only |
| dmemcg-booster 0.1.3 | gitlab.steamos.cloud/holo 4305d74 | D H | no | yes | package, `ogc/dmemcg-booster.bst` | MIT | |
| plasma-foreground-booster, KCGroups | pixelcluster/kcgroups 0.2 | D H | no | yes | package, `ogc/plasma-foreground-booster-dmemcg.bst`, `ogc/kcgroups-dmemcg.bst` | LGPL-2.1 | |
| uresourced-dmemcg | OpenGamingCollective | D | no | **no** | package | LGPL-2.1 | For GNOME. Bazzite uses it on Silverblue only. |
| scx-scheds, scx-tools | sched-ext/scx 1.1.5 | D H | no | **no** | package | GPL-2.0 | Technical: the Rust workspace needs about 800 crates and a BPF Clang. The kernel has sched_ext. Follow-up. |
| cardwire | OpenGamingCollective/cardwire c0a4aa0 | D | switcheroo-control | **no** | package | GPL-3.0 | Technical: its eBPF objects need a nightly Rust and bpf-linker. Tromsø keeps switcheroo-control. |
| game-devices-udev 1.1 | codeberg fabiscafe 811ba06 | D H | no | yes | package, `ogc/game-devices-udev.bst` | MIT | |
| steam-devices udev rules | Valve | D | yes | | | MIT | |
| input-remapper, ds-inhibit, xwiimote-ng, OpenRGB rules | Fedora, Valve | D | no | **no** | package | mixed | Follow-up. OpenRGB rules come with its Flatpak. |
| v4l-utils | freedesktop-sdk | D | no | yes | package | GPL-2.0 | |
| libcec, linux-cec, ddcutil, i2c-tools, lm_sensors | Fedora, OGC | D H | no | **no** | package | GPL | Follow-up: no source element yet |
| ryzenadj, amdsmi, fw-fanctrl, framework-system | Fedora, COPR | D H | no | **no** | package | mixed | `ryzenadj` needs `ryzen_smu` or `/dev/mem`, which lockdown stops. The others: follow-up. |
| asusctl | OpenGamingCollective/asusctl ea92944 | D | no | **no** | package | MPL-2.0 | Not in the desktop image of Bazzite. The kernel drivers are taken. |
| Waydroid, cage, wlr-randr | Fedora | D | no | **no** | package | GPL-3.0 | Technical: it needs LXC and python-gbinder, and downloads an Android image. The kernel has binder. Follow-up. |
| tuned profiles | Bazzite | D | no (`tuned-ppd.bst` is a stub) | **no** | config | Apache-2.0 | Technical: no tuned daemon in Tromsø |
| greenboot, snapper, bees, btrfs-assistant | Fedora | D | btrfsmaintenance | **no** | package | GPL | Technical: the root is ext4 and composefs. greenboot drives rpm-ostree. |
| Homebrew, tailscale, uupd, fastfetch, fish, glow, gum, ydotool, powertop, distrobox, krunner-bazaar, kernel-tools | Bazzite | D | yes or partly | | | | |
| Cockpit, stress-ng, nerd-fonts, yafti portal, ujust recipes, wallpapers, branding, announcements | Bazzite | D | no | **no** | config | mixed | Not a gaming part, or the identity of Bazzite. `docs/branding-audit.md` does not accept the branding of another project. |
| InputPlumber, steamos-manager, powerbuttond, jupiter-fan-control, jupiter-hw-support, steamdeck-dsp, galileo-mura, vpower, sdgyrodsu | Terra, Valve | H | no | **no** | package | mixed | Follow-up variant. No handheld hardware is available, and these daemons write fans, TDP and firmware. |
| gamescope-session, -steam, -ogui-steam, autologin, return-to-gamemode | OpenGamingCollective | H | no | **no** | session | MIT, GPL-3.0 | Technical: the sessions start native Steam (32-bit) |
| plasma-applet-tdp-control | OpenGamingCollective 1d86385 | H | no | **no** | package | GPL-3.0 | It needs steamos-manager |
| jupiter-dock-updater, Steam bootstrap archive | evlaV, Valve | H | no | **no** | binary | proprietary | Licence, and a pre-built binary |
| `bazzite-dx` packages | Bazzite | D | no | **no** | | | The developer image, not a gaming part |

### Configuration

All taken files are in `files/ogc/config`, at the path of the image.

| Bit | Scope | Taken | Reason when skipped or note |
|---|---|---|---|
| sysctl: `vm.max_map_count`, `split_lock_mitigate=0`, BBR and MTU probing, inotify | D | yes | `split_lock_mitigate=0` removes a defence against a local denial of service. Games need it. |
| I/O schedulers, DualSense UCM, Dolphin motion sensors | D | yes | |
| memlock limit, stop timeout of 15 s, zram of 16 GiB with zstd, btrfs reclaim | D | yes | |
| modprobe: `mt7921e`, Framework charge control, `hid_logitech` blacklist | D | yes | |
| `bluetooth.disable_ertm=1` | D | yes | As a modprobe option. Bazzite uses a kernel argument. |
| `ntsync` at boot | D | yes | `ntsync-autoload` in Bazzite |
| udev: Ally, Ally X, AYANEO 3, GPD Win 4, GPD Win Max 2, Steam Controller wake | H | yes | Each rule matches its hardware only |
| udev: `30-steamdeck`, `40-backlights`, `70-steam-jupiter-leds`, `99-valve-leds` | H | **no** | Security: `chmod a+w` on power limits and LEDs. Each local process could write them. |
| udev `80-gpu-reset`, `99-powertargets`, `50-wifi-sleep`, CEC | D H | **no** | They name units that Tromsø does not have, or kill a process as root. Follow-up. |
| sysctl `65-memory`, watchdog off, watchdog blacklist, logind, UPower, BlueZ `main.conf` | H | **no** | Handheld variant. The watchdog is a defence on a desktop. |
| `bazzite-hardware-setup` (kernel arguments per device) | D H | **no** | Technical: it calls `rpm-ostree kargs`. Tromsø is composefs and bootc. Follow-up: kernel arguments by DMI. |
| `20-bazzite.toml` (btrfs, `enforce-container-sigpolicy`) | D | **no** | The kernel rule gives ext4. The signature policy is #478. |
| SELinux workarounds, rpm-ostree and dnf settings | D | **no** | Fedora only |
| BlueZ `UserspaceHID=true` | D | **no** | It is the default of the BlueZ in the image |
| PipeWire and WirePlumber hardware profiles | H | **no** | Their selector services are SteamOS units. Handheld variant. |

## What is proven

The pull request of #550 has the evidence. Handheld hardware, controllers, wheels
and real GPUs are **not proven**: no such hardware is available for this work.
