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

| 2026-07-19 | Multi-runner never went green since May; every run "cancelled" at ~6.5 h | chunk jobs killed by job-level `timeout-minutes` — a cancelled job never reaches the CAS-push step, so 6 h × 10 chunks of build work was discarded daily (≈720 runner-hours; zero chunk cache packages ever existed on GHCR) | build bounded *inside* the step (`timeout 270m`), push steps `if: always()` — partial CAS salvaged, builds converge across days |
| 2026-07-19 | Failed chunks could publish their exact-cache-key tag and be skipped forever | `for i in 1 2 3 … done` retry loop exits 0 on total failure (status of last `sleep`) | retry loop removed (bst retry-failed/network-retries already cover it); rc propagated |

| 2026-07-19 | LUKS e2e / ISO jobs die in seconds: "Unknown attribute `group`" at Justfile:5 | Ubuntu 24.04 apt ships just 1.21 (predates `[group()]`); old runs survived because ancient just silently picked the group-free lowercase justfile we removed | workflows install just via extractions/setup-just and invoke `sudo "$(command -v just)"` |

Keep appending to this table while iterating on CI (see the org `ci-fix-loop`
skill; format proven in tuna-os/tunaos `docs/ci-troubleshooting.md`).

## Channels: nightly (main) and stable

- **main** is the nightly trunk: the daily scheduled multi-runner build
  publishes `:latest`, `:nightly`, `:nightly-YYYYMMDD`, `:<sha>`; the ISO
  lands at R2 `tromso/`.
- **stable** is a release bookmark branch: `promote-stable.yml` (weekly cron
  + dispatch, `force=true` to override) verifies the newest nightly build and
  ISO both succeeded, force-pushes that commit to `stable`, and dispatches
  the stable build → `:stable`, `:stable-YYYYMMDD` tags and an ISO under R2
  `tromso/stable/`. The stable ISO embeds the `:stable` payload
  (payload_ref is rewritten per-channel in build-iso.yml).
- Tracking/renovate PRs only ever target main; stable moves exclusively via
  promotion.

## Release-linked sources

Local elements track upstream **release tags** (globs like `v[0-9]*`), not
dev branches, so the daily `bst source track` lands releases. Exceptions
that intentionally track branches: rolling content repos (aurora common,
docs, wallpapers / xfwl4 dev repos) and junctions (pinned branch). Never pin
`track:` to one exact tag — tracking can then never move it.

## Guard rails (what stops a bad commit)

Pre-merge, required on main (branch protection; automerge fires on green):
shellcheck/yamllint/actionlint, unit suites (BATS + pytest incl. the
52-test luks-unlock suite and `test_iso_invariants.py` — every invariant
assertion encodes a bug class that actually shipped), the BuildStream
graph gate (`bst show --deps all` on the shipping target, junctions
resolved), and `Just Parse`. `pr-build-changed.yml` additionally builds
the elements a PR touches against the warm GHCR core CAS — informational
until the world rebuild converges, then promote to required (tromso#80).

Post-merge: salvage-enabled nightly world build → ISO boot gate
(ready-marker + screenshot artifact) → weekly LUKS install e2e
(screenshots on the `ci-screenshots` branch + PR comments) → weekly
real-hardware KVM boot of the published R2 ISO on the kanpur runner
(`validate-iso-kanpur.yml`). A cloud routine ("tromso + xfce-linux CI
babysitter", every 3 h) diagnoses completed failures from logs and pushes
fixes.

**Rules that keep this healthy:** never add `paths:` filters to workflows
whose jobs are required checks (a non-reporting required check deadlocks
automerge); if a required job is renamed, update the branch-protection
contexts in the same PR; never wrap a gate in `|| echo` (that is how
bst-validate and pytest were silently dead for months).

## kanpur self-hosted runner (validation only)

Org runner `kanpur` (labels `self-hosted, kanpur, vm`) runs in a
privileged `ubuntu:24.04` podman container on the kanpur laptop with
/dev/kvm + /dev/fuse passed through. It exists ONLY for
`validate-iso-kanpur.yml` — kanpur is on slow wifi and must never run
BuildStream or ISO builds (leave `ACTIONS_RUNNER_LABEL` unset).

Ops (on kanpur): container `gh-runner-kanpur`, volumes under
`/var/srv/gh-runner/{runner,work,bst-cache}`, self-provisioning
`runner/start.sh`, restart policy `unless-stopped`. Re-register after a
token wipe: `gh api -X POST orgs/tuna-os/actions/runners/registration-token`
then `./config.sh --unattended --replace --url https://github.com/tuna-os
--token <T> --name kanpur --labels kanpur,vm --work /work` inside the
container (RUNNER_ALLOW_RUNASROOT=1).

## Rollback

`rollback-stable.yml` (dispatch-only, **dry_run defaults to true**) is the
inverse of promotion: verifies the target `:<sha>` image exists, then
`skopeo copy --preserve-digests` onto `:stable` (+ a dated
`stable-rollback-*` tag) and force-pushes the stable branch to the same
commit so branch and tag never diverge. Shares the promote concurrency
group so it cannot race a promotion. Dakota-pattern notes: once signing
lands, add a cosign-verify step before the retag.
