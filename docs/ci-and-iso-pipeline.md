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

The plan, core, and parallel dependency chunks (steps 1-3) use the shared
[tuna-os/bst-ci](https://github.com/tuna-os/bst-ci) reusable workflow. Each
BuildStream desktop repository uses this workflow, with different image names,
targets, and chunk counts. The local `build_final` job (step 4) uses cosign
without a key. This process puts the identity of this workflow in the Fulcio
certificate. The verification instructions in README.md use that identity.

Free GitHub runners can't hold the whole KDE build, so it's split:

1. **plan** — The `scripts/ci-build-matrix.py` script from bst-ci runs
   `bst show`. It splits uncached elements into a core set (first `CORE_SPLIT`)
   and `NUM_CHUNKS` round-robin chunks. Each chunk has a composite cache key.
   The job checks out the script from bst-ci at run time. This repository no
   longer contains a copy.
2. **build_core** — builds the bootstrap set, pushes the CAS as
   `ghcr.io/…/cache-tromso-core:latest` (zstd tarball via oras).
3. **build_deps** (matrix) — each chunk restores core + its own previous CAS,
   builds, pushes `cache-tromso-<chunk>:{latest,<cache-key>}`. The job skips a
   chunk when GHCR already has its exact cache key.
4. **build_final** — merges all chunk CAS tarballs, builds the final target,
   `just export` (squash + OCI labels + chunkify), `just lint`
   (`bootc container lint`), pushes `latest` + date + sha tags (main only).

BuildStream settings CI uses live in the checked-in `buildstream-ci.conf`.

#### Remote execution (tromso#311)

The whole plan, core, chunk and merge design exists because this repository
has no remote executor. Other repositories with one finish the same work in
18 to 22 minutes. `RazorfinOS-org/cosmic-build-meta` is the clearest proof,
because it is one repository before and after the change.

`build_final` now takes its config from
`.github/actions/generate-bst-ci-config`, a port of razorfin's action. The
action reads two credentials:

| name | kind | purpose |
| --- | --- | --- |
| `CASD_CLIENT_CERT` | repository variable | mTLS identity for `cache.projectbluefin.io:11002` |
| `CASD_CLIENT_KEY` | repository secret | the matching private key |

Neither exists yet, and nobody in this repository can create them. Someone
must ask the Bluefin maintainers for a client certificate. Until then the
action writes the committed `buildstream-ci.conf` byte for byte, so the build
behaves as it did before. `tests/pytest/test_bst_ci_config.py` asserts that
equality on every pull request.

Two rules protect the change:

- The action stops the job when a caller asks for remote execution and the
  credentials are absent.
- The build step greps the console for the `Remote Execution Configuration`
  banner. A green cache hit does not prove that BuildStream loaded the
  executor. A quiet fall back to local builds looks like a slow success.

Two steps remain. First, get the certificate. Second, move the junction pins.
Cache keys are a function of the ref, the patch queue, the options and the
overrides. A shared cache therefore stays cold while this repository sits on
freedesktop-sdk 25.08.9 and the others sit on 25.08.16. Delete the chunk
machinery from the caller only after a remote build passes.

**Cache-key invalidation warning:** a change to the cache key of every element
causes a full world rebuild. A change to `name:` in `project.conf` is one example.
Expect chunk jobs to run for hours or reach their six-hour limit once. They
recover after they refresh the GHCR caches.

### Live ISO (`iso.justfile` + `tromso/`)

`just iso-sd-boot tromso` (see `iso.justfile`, imported from `Justfile`):

1. `just container tromso` — 3-stage `tromso/Containerfile`:
   ghcr payload (kernel modules) → Debian stage builds a dmsquash-live
   initramfs (incl. the `95tromso-isofile` Ventoy dracut module) → final
   stage installs flatpaks (`src/install-flatpaks.sh`) and configures the
   live env (`src/configure-live.sh`).
2. The recipe squashes the payload image and imports it into VFS container
   storage inside the squashfs. This process enables the offline installation.
3. `tromso/src/build-iso.sh` assembles a systemd-boot UEFI ISO.

The live session automatically logs in to Plasma as `liveuser`. It starts
`org.tunaos.InstallerKde` from the OCI flatpak remote for tuna-os. A symbolic
link at `/usr/local/bin/fisherman` points to fisherman. It uses the shared
`org.tunaos.Installer.install` polkit action. See INSTALLER-FRONTENDS.md in the
organization workspace.

### LUKS end-to-end test (`test-luks-install.yml`)

Local equivalent:

```bash
just debug=1 iso-sd-boot tromso     # debug=1 enables SSH (liveuser/live)
just luks-test-qemu tromso          # boot → fisherman LUKS install → reboot → unlock
```

`tromso/src/luks-unlock.py` drives the QEMU monitor. It checks screen dumps
until Plymouth appears, types the passphrase with `sendkey`, and verifies the
installed system boot. The workflow publishes screenshots to the
`ci-screenshots` branch and PR comments. They show the live desktop, Plymouth
prompt, and installed desktop.

## Source updates

- **Renovate** (`renovate.json`) — GitHub Actions, container tags. Automerge
  on green CI, majors included.
- **`track-bst-sources.yml`** — Renovate can't parse `.bst`; this runs
  `bst source track` daily across the repo-local element groups. The workflow
  uses its matrix to split updates into focused PRs. It excludes orphaned
  elements that cannot build in the offline sandbox of BuildStream. There is no
  `kde-build-meta.bst` junction or separate junction-update PR. PRs made with
  the default `GITHUB_TOKEN` don't trigger CI — set a `BOT_TOKEN` secret to
  fix that.

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

| 2026-07-20 | Multi-runner `build_deps` chunk jobs queued for 20+ min when `tromso` and `xfce-linux` built simultaneously | Simultaneous schedule triggers and push builds across repos reached free-tier org concurrency cap (~20 jobs) | Removed push triggers; staggered daily crons (xfce-linux at 23:30 UTC, tromso at 00:30 UTC) and accepted residual manual-dispatch contention as free-runner trade-off (tromso#93) |
| 2026-08-12 | Daily `chore(deps): track element sources` PR red on `Build changed elements` (`tromso/glow.bst`: `go: download go1.26.5 … lookup proxy.golang.org … connection refused`) | `glow.bst`/`gum.bst` run `go mod download` in build-commands, but the BuildStream sandbox has no network; they are orphaned (absent from `tromso/deps.bst`), so the world build never built them and only a ref bump touching the file exposes it. glow v3.0.0 additionally wants a Go toolchain newer than freedesktop-sdk 25.08 ships | Both excluded from `track-bst-sources.yml` via `TRACK_EXCLUDE` so a broken element can't block buildable ref bumps. #180 merged red, so glow stays at v3.0.0 on main: reverting the ref would touch the file and trip the same gate. Re-include (and repair the ref) once they vendor modules (`-mod=vendor`, as `uupd.bst` and `kde-linux-deps/toolbox.bst` do) |
| 2026-07-20 | Runner agent process crashes mid-build (`System.IO.IOException: No space left on device`) on heavy chunks (`util-linux-full`, `cryptsetup`, `pwquality`), bypassing `if: always()` CAS salvage | `ublue-os/remove-unwanted-software@v9` freed insufficient disk space compared to `jlumbroso/free-disk-space` (which removes tool-cache), leaving ~25GB instead of ~45GB free | Upstreamed `jlumbroso/free-disk-space@v5` (`tool-cache: true`) to `build_core` in `tuna-os/bst-ci` (matching `build_deps` and `build_final`), increasing free disk space for heavy dependency closures (tromso#96) |

Add rows to this table as you change CI. See the organization `ci-fix-loop`
skill. The `docs/ci-troubleshooting.md` file in tuna-os/tunaos shows the format.

## Channels: nightly (main) and stable

- **main** is the nightly trunk: the daily scheduled multi-runner build
  publishes `:latest`, `:nightly`, `:nightly-YYYYMMDD`, `:<sha>`; the ISO
  lands at R2 `tromso/`.
- **stable** is a release bookmark branch. A weekly schedule or manual dispatch
  starts `promote-stable.yml`; set `force=true` for an override. The workflow
  verifies the newest nightly build and ISO. It force-pushes that commit to
  `stable` and starts the stable build. The build creates the `:stable` and
  `:stable-YYYYMMDD` tags, plus an ISO under R2 `tromso/stable/`. The stable ISO
  embeds the `:stable` payload. The build-iso.yml workflow changes `payload_ref`
  for each channel.
- Update PRs from source trackers or Renovate target only main. Stable moves
  only through promotion.

## Release-linked sources

Local elements use upstream **release tags** (globs such as `v[0-9]*`) instead
of development branches. Thus, the daily `bst source track` selects releases.
Some content repositories use branches, such as aurora common, docs,
wallpapers, and the xfwl4 development repositories. Junctions also use a fixed
branch. Do not set `track:` to one exact tag, because the tracker cannot move it.

## Guard rails (what stops a bad commit)

Branch protection on main needs pre-merge checks. These checks include
shellcheck, yamllint, actionlint, BATS, pytest, the 52-test luks-unlock suite,
and `test_iso_invariants.py`. Each invariant represents a class of defect that
reached a release. The BuildStream graph gate runs `bst show --deps all` on the
release target with resolved junctions.

`Just Parse` is also a gate. Add the multi-runner result to branch protection
after the world rebuild converges (tromso#80). The scheduled or manual
multi-runner workflow is the only path to build and publish an image. This
design gives one shared CAS and one final signer.

Post-merge: salvage-enabled nightly world build → ISO boot gate
(ready-marker + screenshot artifact) → weekly LUKS install e2e
(screenshots on the `ci-screenshots` branch + PR comments). A cloud
routine ("tromso + xfce-linux CI babysitter", every 3 h) diagnoses
completed failures from logs and pushes fixes.

**Rules that keep this healthy:** do not add `paths:` filters to workflows
with required checks. If a required check does not report, automerge cannot
continue. If you rename a required job, update the branch-protection contexts
in the same PR. Do not wrap a gate in `|| echo`; this error hid failures in
bst-validate and pytest for months.

## Rollback

`rollback-stable.yml` runs only after a manual dispatch, and `dry_run` defaults
to true. It reverses a promotion. The workflow verifies that the target
`:<sha>` image exists. Then, `skopeo copy --preserve-digests` puts it on
`:stable` and a dated `stable-rollback-*` tag. It force-pushes the stable branch
to the same commit, so the branch and tag cannot diverge. It shares the
concurrency group for promotion and cannot run at the same time.

This workflow does not restore a full release. It restores only the x86_64
`:stable` tag and the git branch. The `-aarch64` tags and R2 ISO under
`tromso/stable/` stay on the bad build. The workflow does not use
`cosign verify` on the target before the new tag. Signatures are available
because `build-tromso-multirunner.yml` signs each pushed digest. The
[rollback runbook](../runbooks/rollback-a-bad-stable-release.md) gives the
manual steps for other artifacts and the final verification.
