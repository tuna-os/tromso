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

## Next steps (in order)

1. Run `oci-export.sh` where user namespaces + bootc exist (this dev host
   has neither: `unshare -Urm` is denied, no `bootc` binary) and record
   wall time + size vs the `bst` tromso image.
2. Boot `boot-demo` in QEMU where `/dev/kvm` exists.
3. Verdict: keep tine for DDIs, drop it, or revisit after upstream KDE
   BuildStream work (issue #85) lands.

## Guard rails for this experiment

- Do not add `tine-poc` to any workflow, `Justfile` recipe, or required
  check; do not rename jobs; do not add `paths:` filters (see AGENTS.md).
- Do not touch `elements/`, `project.conf`, or `include/` from this branch
  — the comparison is only valid while the BuildStream side is unchanged.
