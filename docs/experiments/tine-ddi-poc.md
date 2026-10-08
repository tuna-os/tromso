# tine DDI experiment (`exp/tine-ddi-poc`)

Question: can [tine](https://github.com/amutable-systems/tine) (Buck2-based,
see [announcement](https://amutable.com/blog/tine-build-system)) build a
bootable Tromso/KDE artifact cheaper than BuildStream, for DDI-format images?

## Status: scaffold only

Branch pins tine as a shallow submodule (`tine/`, commit `181b6c5`,
2026-10-07) and adds a minimal PoC (`tine-poc/BUCK`). Nothing is wired to
CI, the `Justfile`, `project.conf`, or `elements/` — the BuildStream
pipeline builds exactly as before.

## What tine can and cannot do (verified 2026-10-07)

- Outputs: tar rootfs, UKI, dm-verity GPT disks (`raw`/`qcow2`
  subtargets), sysext images, SBOMs, QEMU `vm` test targets.
- Inputs: upstream binary packages (Fedora Rawhide / Arch / Debian
  snapshot catalogs) + locally built RPMs, Go, Rust. No source-built
  freedesktop-sdk/KDE stack — a switch would mean consuming Fedora KDE
  RPMs or porting every KDE module to tine `rpm` rules.
- **No bootc/OCI/ostree/composefs support** (verified by grep over the
  checkout). So: DDI experiment yes, bootc replacement no.

## How to run the PoC

```sh
tine/bin/tine init                                     # one-time cell setup
tine/bin/tine buck build //tine-poc:boot-demo.fedora   # minimal DDI
tine/bin/tine buck run //tine-poc:boot-demo-vm.fedora  # boot it in QEMU
```

Host needs: Linux user namespaces, python3, git, `/dev/kvm` for VMs.

## bootc/OCI output (`tine-poc/oci-export.sh`)

tine has no OCI rule, so the experiment converts tine output instead of
replacing it: `//tine-poc:kde-rootfs` (all package names verified against
the pinned `fedora.rawhide.x86_64.json` snapshot) is exported as a tar,
assembled `buildah from scratch` with the `containers.bootc=1` /
`ostree.bootable=1` labels, and validated with `bootc container lint`:

```sh
./tine-poc/oci-export.sh tine-kde:latest
```

Known unknowns for the first run: whether kernel `%post`/dracut produces
an initramfs inside tine's box (lint will say), and whether the chrooted
`systemctl enable sddm` / `set-default graphical.target` ops behave like
their `elements/tromso/system-config.bst` equivalents.

## Head-to-head race (`.github/workflows/tine-race.yml`)

Non-required experiment workflow: on `workflow_dispatch` or push to
`exp/tine-ddi-poc`, one `ubuntu-24.04` runner (cold cache) times the tine
`boot-demo` + `kde-rootfs` builds, exports the OCI layout
(`--skip-lint`: no bootc on runners — recorded in the manifest, not
hidden), then baselines against `ghcr.io/tuna-os/tromso:latest` size and
the last green multi-runner duration. Artifact: `tine-race-manifest`
(30 days). Fair-reading caveat lives in the manifest: functional parity,
not identical inputs (Fedora binary RPMs vs source-built KDE).

## Troubleshooting log (symptom → cause → fix)

- 2026-10-07, run 37677974715 red: `unshare -Urm` denied on
  `ubuntu-24.04` → GH runners AppArmor-restrict unprivileged userns →
  best-effort `sysctl kernel.apparmor_restrict_unprivileged_userns=0`
  before the probe (run 37678608395 green).
- Same run: `kde_tar_bytes=59` → buck-out outputs are CAS symlinks and
  plain `du` measured the link → `stat -L -c %s`.
- 2026-10-07, corral `bootc create tine-kde` red at `bootc install
  to-disk` with zero output → layer inspection of `race-38fa511d`:
  image ships vmlinuz but no `bootc` binary and no `initramfs.img`
  (kernel %post/dracut never ran in tine's box) → added `bootc`,
  `bootupd`, `systemd-boot-unsigned`, `shim-x64`, `grub2-efi-x64`,
  `selinux-policy-targeted`, `ostree` + explicit chrooted dracut op.
- Same day, `race-f35ac4ca` install failed audibly:
  `Failed to find ostree/prepare-root.conf` (corral picks the
  composefs backend once systemd-boot exists). Filelists proof: no RPM
  ships it live, only a doc sample in `bootc` → author canonical
  `[composefs] enabled = true` via `image.write_file`.
- `race-0e89b443`: `Creating root filesystem (btrfs) on /dev/vdc3`
  then bare ENOENT → bootc execs `mkfs.*` from the target image and ours
  lacked all of them → added `btrfs-progs`, `xfsprogs`, `dosfstools`,
  `e2fsprogs`.
- `bootc container lint` (run in the utah VM against the VM-built image,
  12 pass): FAIL `baseimage-root: Missing /sysroot` → `mkdir /sysroot`
  op; WARN `nonempty-boot` (`/boot/efi`, `/boot/grub2` from shim/grub2)
  → `rm -rf` op keeping empty `/boot`. Also fixed `oci-export.sh`:
  lint takes `--rootfs DIR`, not an image ref.
- OPEN: same BUCK+pin builds DIFFERENT tars per host. CI `race-0e89b443`
  layer lacks `mkfs.btrfs` et al, but its own `pkgdb.sqlite` (decoded via
  string scan: solver DID record `btrfs-progs`, `xfsprogs`, `dosfstools`,
  `e2fsprogs`) and the utah-VM-built tar from identical inputs HAS all of
  them; tar→buildah copy verified lossless. So files vanish between rpm
  install and tar on the GH runner only — suspect tine install/finalize
  host-dependence, not the solver. Next step: upstream issue to
  amutable-systems/tine (deferred while booting: latest CI image
  `race-2c40823f` HAS the tools, so current line is green regardless).
- `race-83f7d6e4` installs (`CORRAL_BUILD_OK`) but the guest drops to a
  dracut emergency shell at `initrd-switch-root`: unpacked initramfs has
  NO ostree dracut module (its `check()` declines unless forced; the
  `50ostree` dir ships in the `ostree` package but dracut skips it) →
  `--add ostree` on the dracut op. Read via
  `virsh dumpxml` → serial `-log` file in the virt-launcher pod
  (`virtctl console` alone shows nothing after the fact).
- Still emergency: `ostree-prepare-root` correctly SKIPS (needs bare
  `ostree` karg; composefs flow uses bootc's own `bootc-root-setup`,
  conditioned on `composefs*` kargs) — but our initrd lacks bootc's
  dracut module too (`51bootc/` ships in image, declined like ostree)
  → `--add "ostree bootc"`. Interactive emergency-shell diagnosis works
  via staged stdin to `virtctl console`.
- `race-02648877` boots past switch-root into systemd-firstboot
  "Initial Setup" (interactive timezone prompt stalls boot): pre-seed
  `/etc/locale.conf`, `/etc/hostname`, `/etc/localtime` symlink via ops
  (zoneinfo ships; factory locale.conf is not applied).
- Same image, SSH `Permission denied (publickey)` despite correct key
  file (600, right key): file labeled `var_t`, sshd enforcing → denied.
  bootc writes the key via tmpfiles without proper context. Fix in
  image: first-boot oneshot `restorecon -R /root/.ssh` before sshd,
  plus mask `systemd-firstboot.service` (only remaining prompt was root
  password; image is key-only by design).

## Harness validation via utah (2026-10-07)

`ghcr.io/projectbluefin/utah:testing` (Bluefin-on-Hummingbird bootc
image) through the same corral/KubeVirt path (`corral bootc create
utah-test`, composefs/btrfs backend): `CORRAL_BUILD_OK`, VM boots, SSH
works (`NAME="Utah"`, bootc 1.16.13). The harness is proven — remaining
failures are tine image content, not the cluster. Reference answers
from the live utah VM (`rpm -qf`): `mkfs.btrfs` ← `btrfs-progs`,
`mkfs.vfat` ← `dosfstools`, `prepare-root.conf` owned by NO package
(image-authored, matching our `write_file`), `bootc`/`bootupd` present.
(`mkfs.xfs` absent even there — xfs backend unsupported by reference.)

## Race result (2026-10-07, run 37681045503, `ubuntu-24.04` cold cache)

| side | build time | shipped bytes |
|---|---|---|
| tine `boot-demo` DDI (raw disk) | 69 s | — (disk artifact, not measured) |
| tine `kde-rootfs` tar | 106 s | 2.24 GB (uncompressed) |
| tine kde OCI (`containers.bootc` labels, lint SKIPPED) | same build | 1.01 GB on disk (gzip-compressed layers) |
| tromso bst `ghcr.io/tuna-os/tromso:latest` | ~487 min (run 37580695717) | 8.52 GB (`docker inspect` = uncompressed) |

Fair reading: the time gap mostly measures binary-RPM assembly vs
from-source compilation, not tool superiority. The size gap is partly
real (tine image is a minimal KDE set; tromso ships the full stack) and
partly compression accounting (compare 8.52 GB ↔ 2.24 GB uncompressed,
≈3.8×). Blocking before any switch talk: `bootc container lint` has
never passed — no bootc binary on GH runners or this dev host.

## Next steps (in order)

1. Run `bootc container lint` on the tine OCI where bootc exists.
2. Boot `boot-demo` in QEMU where `/dev/kvm` exists.
3. Verdict: keep tine for DDIs, drop it, or revisit after upstream KDE
   BuildStream work (issue #85) lands.

## Guard rails for this experiment

- Do not add `tine-poc` to any workflow, `Justfile` recipe, or required
  check; do not rename jobs; do not add `paths:` filters (see AGENTS.md).
- Do not touch `elements/`, `project.conf`, or `include/` from this branch
  — the comparison is only valid while the BuildStream side is unchanged.
