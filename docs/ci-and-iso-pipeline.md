# CI & ISO pipeline

How Tromsø gets from `.bst` elements to a bootable, installable live ISO —
and how to debug it when it breaks. (Same architecture as tuna-os/xfce-linux;
patterns originate in projectbluefin/dakota and dakota-iso.)

## Build chain

```
elements/**  ──►  Build Tromso (Multi-Runner)  ──►  ghcr.io/tuna-os/tromso:latest
                        │ (workflow_run)
                        ▼
              Build and Publish Tromsø Live ISO  ──►  R2: tromso/tromso-live-*.iso
                        │
                        ▼ (boot gate: TROMSO_LIVE_READY on serial + screenshot)
              LUKS Install End-to-End Test (PR / weekly / dispatch)
```

### Multi-runner build (`build-tromso-multirunner.yml`)

Free GitHub runners can't hold the whole KDE build, so it's split:

1. **planning** — `scripts/ci-build-matrix.py` runs `bst show` and splits
   uncached elements into a core set (first `CORE_SPLIT`) and `NUM_CHUNKS`
   round-robin chunks, each with a composite cache key.
2. **build_core** — builds the bootstrap set, pushes the CAS as
   `ghcr.io/…/cache-tromso-core:latest` (zstd tarball via oras).
3. **build_deps** (matrix) — each chunk restores core + its own previous CAS,
   builds, pushes `cache-tromso-<chunk>:{latest,<cache-key>}`. A chunk whose
   exact cache key already exists on GHCR is skipped entirely.
4. **build_final** — merges all chunk CAS tarballs, builds the final target,
   `just export` (squash + OCI labels + chunkify), `just lint`
   (`bootc container lint`), pushes `latest` + date + sha tags (main only).

BuildStream settings CI uses live in the checked-in `buildstream-ci.conf`.

**Cache-key invalidation warning:** anything that changes every element's
cache key (e.g. renaming `name:` in `project.conf`) triggers a full world
rebuild — expect chunk jobs to run for hours or hit their 6 h timeout once,
then recover from the refreshed GHCR caches.

### Live ISO (`iso.justfile` + `tromso/`)

`just iso-sd-boot tromso` (see `iso.justfile`, imported from `Justfile`):

1. `just container tromso` — 3-stage `tromso/Containerfile`:
   ghcr payload (kernel modules) → Debian stage builds a dmsquash-live
   initramfs (incl. the `95tromso-isofile` Ventoy dracut module) → final
   stage installs flatpaks (`src/install-flatpaks.sh`) and configures the
   live env (`src/configure-live.sh`).
2. The payload image is squashed and imported into a VFS containers-storage
   inside the squashfs — that's what makes the offline self-install work.
3. `tromso/src/build-iso.sh` assembles a systemd-boot UEFI ISO.

The live session autologs into Plasma as `liveuser` and autostarts
`org.tunaos.InstallerKde` (from the tuna-os OCI flatpak remote); fisherman is
symlinked to `/usr/local/bin/fisherman` with the shared
`org.tunaos.Installer.install` polkit action (see INSTALLER-FRONTENDS.md in
the org workspace).

### LUKS end-to-end test (`test-luks-install.yml`)

Local equivalent:

```bash
just debug=1 iso-sd-boot tromso     # debug=1 enables SSH (liveuser/live)
just luks-test-qemu tromso          # boot → fisherman LUKS install → reboot → unlock
```

`tromso/src/luks-unlock.py` drives the QEMU monitor: waits for Plymouth via
screendump polling, types the passphrase with `sendkey`, verifies the
installed system boots. Screenshots (live desktop, Plymouth prompt, installed
desktop) are published to the `ci-screenshots` branch and PR comments.

## Source updates

- **Renovate** (`renovate.json`) — GitHub Actions, container tags. Automerge
  on green CI, majors included.
- **`track-bst-sources.yml`** — Renovate can't parse `.bst`; this runs
  `bst source track` daily. Local elements (`elements/tromso`,
  `elements/gnomeos-deps`) go into one automergeable PR; the
  `kde-build-meta.bst` junction gets a separate review-required PR (a
  junction bump can rebuild the world). PRs made with the default
  `GITHUB_TOKEN` don't trigger CI — set a `BOT_TOKEN` secret to fix that.

## Troubleshooting log (symptom → root cause → fix)

| Date | Symptom | Root cause | Fix |
|---|---|---|---|
| 2026-07-19 | Every `just` call in CI fails: "multiple candidate justfiles" | `justfile` + `Justfile` both at root; just ≥1.30 hard-errors | ISO recipes moved to `iso.justfile`, imported from `Justfile` |
| 2026-07-19 | `just iso-sd-boot tromso` in build-iso.yml never worked | recipe + `tromso/Containerfile` + dracut module never existed in this repo | ported from xfce-linux/dakota-iso (PR #74) |
| 2026-07-19 | `tromso/Containerfile` missing from git after commit | `.gitignore` had unanchored `Containerfile` rule | anchored to `/Containerfile` |
| 2026-07-19 | All 10 chunk jobs building for 5+ h | `project.conf` `name:` aurora→tromso changed every cache key → world rebuild | expected one-time cost; caches repopulate |
| 2026-07-19 | Installer flatpak never launched in live session | ISO baked `org.bootcinstaller.Installer` but autostart/symlink pointed elsewhere | both sides now use `org.tunaos.InstallerKde` |

Keep appending to this table while iterating on CI (see the org `ci-fix-loop`
skill; format proven in tuna-os/tunaos `docs/ci-troubleshooting.md`).
