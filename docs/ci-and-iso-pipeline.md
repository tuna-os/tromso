# CI & ISO pipeline

How Tromsø gets from `.bst` elements to a bootable, installable live ISO —
and how to debug it when it breaks. (Same architecture as tuna-os/xfce-linux;
patterns originate in projectbluefin/dakota and dakota-iso.)

## Build chain

```
elements/**  ──►  Build Tromso (Multi-Runner)  ──►  ghcr.io/tuna-os/tromso:latest
                        │ (workflow_run)
                        ▼
              Build local ISO → sign → UEFI boot gate → R2 dated objects → latest aliases
                        │
                        ▼ (boot gate: TROMSO_LIVE_READY on serial + screenshot)
              LUKS Install End-to-End Test (PR round-robin / weekly / dispatch)
```

### Multi-runner build (`build-tromso-multirunner.yml`)

The plan, core, and parallel dependency chunks (steps 1-3) use the shared
[tuna-os/bst-ci](https://github.com/tuna-os/bst-ci) reusable workflow. Each
BuildStream desktop repository uses this workflow, with different image names,
targets, and chunk counts. The local `build_final` job (step 4) uses cosign
without a key. This process puts the identity of this workflow in the Fulcio
certificate. The verification instructions in README.md use that identity.

Image publication uses the digest from `podman push --digestfile`.
Local image digests can differ after compression during the push.
Candidate and channel publications both run Trivy on the pushed digest.
If the scan or SARIF upload fails, the job fails.
The scan reports vulnerabilities but does not need a clean report to pass.
A successful build alone does not prove a clean security report.

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

Sources use a separate Actions cache at `~/.cache/buildstream/sources`.
`just bst` mounts this HOME directory. Keys include architecture and the
element/configuration inputs. A restore prefix lets CI reuse sources.
Archives of the CAS do not include sources.

`cache.quota: 60G` limits the active CAS. This reserves space for sources,
build sandboxes and OCI export. An old archive can exceed disk capacity
before BuildStream can prune it.

Builds from all branches use the same concurrency group. This group does not
cancel an active build. Branches write the same CAS tags, so concurrent builds could
replace newer cache progress with an older snapshot.

For branch qualification, dispatch the image workflow with `push_image=false`
and `publish_candidate=true`. It publishes only `ghcr.io/tuna-os/tromso:<sha>`,
never a channel alias. Pass that exact ref to the `payload_ref` input of the
plain, LUKS and ISO workflows. For a branch ISO, set `skip_upload=true`.

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

Two steps remain. First, get the certificate. Second, keep the junction pins
near the pins of the other repositories. Cache keys are a function of the ref,
the patch queue, the options and the overrides. This repository pins
freedesktop-sdk 25.08.17, the same ref as razorfin. Dakota and zirconium use
26.08, so a move to 26.08 is a separate decision.

Delete the chunk machinery from the caller only after a remote build passes.

**Cache-key invalidation warning:** a change to the cache key of every element
causes a full world rebuild. A change to `name:` in `project.conf` is one example.
Expect chunk jobs to run for hours or reach their six-hour limit once. They
recover after they refresh the GHCR caches.

### Live ISO (`iso.justfile` + `tromso/`)

`just iso-sd-boot tromso` (see `iso.justfile`, imported from `Justfile`):

1. Resolve the source to a registry digest. `scripts/prepare-payload.sh`
   follows Dakota's composefs preparation: add the root mount policy, squash
   to one layer, and set `ostree.final-diffid` in both label and annotation.
   The helper checks this metadata before it publishes a local cache tag.
   The tag includes the source digest and preparation version.
2. `just container tromso` uses this prepared image for the live base.
   The Debian stage builds a dmsquash-live initramfs. The final stage adds
   Flatpaks and the configuration for the live session.
3. `scripts/embed-oci-payload.sh` exports that same prepared image to the
   gzip OCI layout at `/usr/lib/tunaos/payload`. It writes
   `/etc/bootc-installer/media-input.json` from the actual manifest and config.
   Fisherman verifies the layout before disk writes. No VFS graphroot or
   network fallback is used. The catalog keeps a separate ref for updates.
4. `usr-lib-tunaos-payload.mount` binds the layout read-only. The live overlay
   alone is writable to `statfs`, even with squashfs beneath it.
   The ready marker needs this mount. If the mount fails, publication stops.
5. `tromso/src/build-iso.sh` assembles a systemd-boot UEFI ISO.

The recipe writes `<target>-payload-ref` in its actual output directory.
CI copies that file with the ISO into `output/`.
The qualification record uses this exact source digest.

The ISO job uses the official Sigstore CLI to sign bytes from a stream.
Its bundle binds the SHA-256 of the actual ISO, not a checksum file.
Cosign 3.0.6 checks the bundle with a hash read from the actual bytes.
It checks the exact workflow identity and GitHub issuer.
A check of a truncated copy must fail.

These signature checks also run when `skip_upload=true`, without an R2 upload.
Earlier 9.36 GB probes did not sign ISOs. They do not prove this new path.
The actual large-ISO run must supply that evidence.

The live session automatically logs in to Plasma as `liveuser`. It starts
`org.tunaos.InstallerKde` from the OCI flatpak remote for tuna-os. A symbolic
link at `/usr/local/bin/fisherman` points to fisherman. It uses the shared
`org.tunaos.Installer.install` polkit action. See INSTALLER-FRONTENDS.md in the
organization workspace.

Publication fails closed. The candidate must pass the UEFI ready-token assertion
and capture a stable, non-dark frame before any upload to R2. The workflow
uploads an ISO, checksum and Sigstore bundle under dated names. Only then
does it update the latest aliases.

Dated names include the run ID and `run_attempt`. `rclone --immutable` rejects
replacement. The workflow publishes the latest checksum and updates the ISO
alias last. R2 has no transaction across these aliases. A promotion failure can
leave mixed sidecars, but the workflow fails. The dated objects remain consistent.

The headless checks use `virtio-vga`, as the VNC recipes do. This selects the
same GPU for live and installed boots. We do not override the renderer or hide
graphics errors. Fonts still need evidence from the actual candidate.

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
| 2026-11-02 | Plain in 41447171165 completes installation but fails its five-minute boot wait | The VM reaches a getty prompt; serial output contains no display-manager start message, which the plain predicate required | Reuse the boot parser with a generic getty marker and require the strict graphical wait; emergency, timeout, or graphical failure must still fail |
| 2026-11-02 | Five chunks in candidate 41390175592 lose their archives after the soft budget; final assembly is skipped | The host `just` process exits but BuildStream still writes to CAS, so `tar` reports `file changed as we read it` and exits 1 | Pin bst-ci `200ad7c`, which stops the builders before archive creation; preserve `pipefail` rather than suppress the archive failure |
| 2026-11-02 | Candidate 41390175592 cannot fetch `pam-wrapper.bst` from `git.samba.org` | The runner reports an unreachable network after 120 seconds; `--on-error continue` then spends its remaining budget elsewhere | Use cwrap's GitLab repository with the same `pam_wrapper-1.1.8` commit; actual pinned-container source fetch succeeds with one processed source and zero failures, preserving the artifact key |
| 2026-11-02 | Both installs in 41395843658 fail with `Unexpected EOF in splitstream` after media verification | [INFERENCE] Dropped source-only composefs preparation left the original layers; the precise EOF mechanism is not yet proven | Restore Dakota's squash, root policy and final-diffid contract before both live customization and OCI export; rerun 41447171165 completes both installs and LUKS unlocks to the installed login screen |
| 2026-11-02 | ISO 41395837392 reports ready after 25 seconds but its screenshot is black | The serial marker precedes a rendered session; the capture occurred immediately | Use the existing graphical wait before capture; fail on dark/unstable timeout or screenshot-copy error instead of returning success |
| 2026-11-02 | Shipped bootc installation policy has no effect | `00-tromso.conf` is not the `.toml` file bootc reads; its bare `btrfs` value is invalid TOML | Ship `00-tromso.toml` with quoted filesystem and explicit root mount policy; actual element commands emitted a parseable policy |
| 2026-11-02 | Python producer test and both debug ISO jobs fail in 41392502489 | Ubuntu 24.04 supplies skopeo 1.13.3, without `--dest-force-compress-format`; initial host smoke used a newer binary | Use OCI destination `--dest-compress-format gzip` only; all 269 tests pass with Ubuntu's binary, final 15 ISO tests pass, and actual Fedora copy verifies gzip bytes and all descriptors without warnings |
| 2026-11-02 | ISO 41390885095 fails payload preflight | Digest pin retained the tag (`:latest@sha256:…`), which skopeo rejects | Construct the canonical ref from inspect `.Name + "@" + .Digest`; real GHCR tag and digest inspection both succeed with identical digest |
| 2026-11-02 | Main build 41281483906 fails in WebKit CMake | Unset link target expands into malformed condition | Integrate existing #427 backport rather than bypass WebKit |
| 2026-11-02 | ISO 41244306172 fails signing before boot check | cosign requires a bundle; detached signature/certificate flags no longer provide the output contract | Publish and document `.bundle`; retain the existing #411 boot-before-publication gate |
| 2026-11-02 | Plain and LUKS in 41257942781 reach live Plasma, then refuse installation | New fisherman requires immutable `media-input.json`; legacy VFS-only media has none | Embed one OCI layout, generate metadata from actual output, bind empty-image E2E recipes to that source, and pin live/payload digests together |
| 2026-11-02 | Repeated source downloads and growing historical CAS | Sources cached outside the HOME directory mounted by `just bst`; sources duplicated in CAS archives; no explicit CAS quota | Pin bst-ci source-cache correction, restore the same HOME source cache in final assembly, retain sources until save, set 60G quota |
| 2026-10-24 | CI executes Actions and reusable workflows through mutable tags/branches (#375) | Moving references can change executable code without a repository review | Pin remote `uses:` to full commit SHAs and Docker Actions to SHA-256 digests; `test_github_actions_use_immutable_references` prevents regressions |
| 2026-10-24 | Four workflows inherited repository token defaults (#321) | Job-level permissions did not constrain other jobs | Add top-level `contents: read`; retain job overrides and require explicit workflow permissions in the invariant tests |
| 2026-10-24 | Main publish stops in WebKitGTK CMake configuration (run 40064106136, #392) | WebKit 2.53.1 expands unset `_linked_into` into missing `if()` arguments in `_WEBKIT_TARGET_LINK_FRAMEWORK` | Backport the exact condition from WebKitGTK 2.54.1 used by gnome-build-meta; keep variable names unexpanded so CMake handles the unset value |
| 2026-10-24 | Unverified ISO could replace public latest (#334) | Upload preceded boot verification and ignored R2 failures | Boot gate precedes publication; immutable dated set completes before latest aliases; upload failures fail the job |
| 2026-07-19 | Every `just` call in CI fails: "multiple candidate justfiles" | `justfile` + `Justfile` both at root; just ≥1.30 hard-errors | ISO recipes moved to `iso.justfile`, imported from `Justfile` |
| 2026-07-19 | `just iso-sd-boot tromso` in build-iso.yml never worked | recipe + `tromso/Containerfile` + dracut module never existed in this repo | ported from xfce-linux/dakota-iso (PR #74) |
| 2026-07-19 | `tromso/Containerfile` missing from git after commit | `.gitignore` had unanchored `Containerfile` rule | anchored to `/Containerfile` |
| 2026-07-19 | All 10 chunk jobs building for 5+ h | `project.conf` `name:` aurora→tromso changed every cache key → world rebuild | expected one-time cost; caches repopulate |
| 2026-07-19 | Installer flatpak never launched in live session | ISO baked `org.bootcinstaller.Installer` but autostart/symlink pointed elsewhere | both sides now use `org.tunaos.InstallerKde` |

| 2026-07-19 | Multi-runner never went green since May; every run "cancelled" at ~6.5 h | chunk jobs killed by job-level `timeout-minutes` — a cancelled job never reaches the CAS-push step, so 6 h × 10 chunks of build work was discarded daily (≈720 runner-hours; zero chunk cache packages ever existed on GHCR) | build bounded *inside* the step (`timeout 270m`), push steps `if: always()` — partial CAS salvaged, builds converge across days |
| 2026-07-19 | Failed chunks could publish their exact-cache-key tag and be skipped forever | `for i in 1 2 3 … done` retry loop exits 0 on total failure (status of last `sleep`) | retry loop removed (bst retry-failed/network-retries already cover it); rc propagated |
| 2026-10-03 | `build_final` (run 37069338183) fails integrating `oci/kde-linux/filesystem.bst` and `oci/layers/tromso-runtime.bst`: `setcap cap_sys_nice+ep /usr/bin/kwin_wayland` exit 1 | `oci/kde-linux/stack.bst` ran `setcap` as a public integration command; BuildStream's sandbox cannot write `security.capability` xattrs, so every compose that stages the stack failed. Present since May, first hit once chunks stopped timing out | setcap moved to the fakecap-preloaded OCI assembly scripts (`oci/kde-linux/image.bst`, already in `oci/tromso.bst`), the freedesktop-sdk pattern (see its `components/shadow.bst`); build_final now `getcap`s kwin_wayland in the exported image |
| 2026-10-03 | `build_final` (run 37102603548) fails in `oci/kde-linux/image.bst`: `glib-compile-schemas` exit 127 | the element never declared `components/glib.bst`; first reached once the setcap fix let the compose elements integrate | `freedesktop-sdk.bst:components/glib.bst` added to its build-depends (as `oci/tromso.bst` already has) |
| 2026-10-04 | First published `tromso:latest` breaks the ISO/E2E `container` recipe: `buildah commit --squash` fails with `lstat /etc/alsa/conf.d/50-arcam-av-ctl.conf: no such file or directory`; 65 `c?????????` entries in the mounted image | freedesktop-sdk build-oci `analyze_lowers()` dropped only the directory entry on a `.wh.<dir>` whiteout, not its descendants. The kde-linux layer whites out `/etc/alsa` (and `/etc/fonts`, `/usr/share/licenses/freedesktop-sdk`); the tromso layer recreates them and build-oci then emitted whiteouts for files that no longer exist. Over a whiteout the recreated directory is not merged, so overlayfs lists those whiteouts as unstattable char devices | `patches/freedesktop-sdk/0012` fixes `analyze_lowers()`; build_final fails on any char device in the exported image; `.gitignore` no longer swallows new `patches/` files |

| 2026-07-20 | Multi-runner `build_deps` chunk jobs queued for 20+ min when `tromso` and `xfce-linux` built simultaneously | Simultaneous schedule triggers and push builds across repos reached free-tier org concurrency cap (~20 jobs) | Removed push triggers; staggered daily crons (xfce-linux at 23:30 UTC, tromso at 00:30 UTC) and accepted residual manual-dispatch contention as free-runner trade-off (tromso#93) |
| 2026-08-12 | Daily `chore(deps): track element sources` PR red on `Build changed elements` (`tromso/glow.bst`: `go: download go1.26.5 … lookup proxy.golang.org … connection refused`) | `glow.bst`/`gum.bst` run `go mod download` in build-commands, but the BuildStream sandbox has no network; they are orphaned (absent from `tromso/deps.bst`), so the world build never built them and only a ref bump touching the file exposes it. glow v3.0.0 additionally wants a Go toolchain newer than freedesktop-sdk 25.08 ships | Both excluded from `track-bst-sources.yml` via `TRACK_EXCLUDE` so a broken element can't block buildable ref bumps. #180 merged red, so glow stays at v3.0.0 on main: reverting the ref would touch the file and trip the same gate. Re-include (and repair the ref) once they vendor modules (`-mod=vendor`, as `uupd.bst` and `kde-linux-deps/toolbox.bst` do) |
| 2026-07-20 | Runner agent process crashes mid-build (`System.IO.IOException: No space left on device`) on heavy chunks (`util-linux-full`, `cryptsetup`, `pwquality`), bypassing `if: always()` CAS salvage | `ublue-os/remove-unwanted-software@v9` freed insufficient disk space compared to `jlumbroso/free-disk-space` (which removes tool-cache), leaving ~25GB instead of ~45GB free | Upstreamed `jlumbroso/free-disk-space@v5` (`tool-cache: true`) to `build_core` in `tuna-os/bst-ci` (matching `build_deps` and `build_final`), increasing free disk space for heavy dependency closures (tromso#96) |

Add rows to this table as you change CI. See the organization `ci-fix-loop`
skill. The `docs/ci-troubleshooting.md` file in tuna-os/tunaos shows the format.

Local checks: 297 pytest tests passed, with one pre-existing expected failure.
Seven subtests also passed.
All 19 BATS tests passed. `actionlint` and `just --summary` passed.
ShellCheck passed at the error severity that CI uses. YAML checks reported only
warnings about line length.

We used the actual producer for OCI media to copy `fedora-minimal:44`.
It verified every blob digest and size. We executed the install commands for
the identity assets. We also signed and verified a Sigstore bundle with a local key.

We also prepared the actual published Tromsø image with native Podman.
We combined six layers into one. Both the label and annotation matched its diff ID.
A second call reused the cache without build output.

Native Skopeo exported it as one gzip layer. We verified every blob digest and size,
preserved metadata, and the root policy inside the archive. This does not
prove that bootc can install or boot it.

Permanent tests use `skopeo` with a valid OCI fixture. They verify the gzip
layer and all digests, and reject an absent source. These checks do not prove a
Tromsø boot or installed desktop. They do not verify signatures from GitHub OIDC.
The candidate workflows must supply the full build and KVM install evidence.

Trivy 0.70.0 scanned the older published payload at digest `2b89f634`.
It fetched the current database and completed in 160 seconds.
The SARIF report has 437 findings across 78 unique IDs and 17 locations.
We have not assessed whether each report applies.
This is not a clean security result or a scan of the current candidate.

We used the native script to check commit `bf255cec` and image `2b89f634`.
It verified the GitHub issuer, publisher workflow and certificate commit.
A check with an incorrect SHA did not pass.
The real health check also refused main ISO run `41403728621`.
That run has no exact-image artifact, even with `force=true`.
No stable image tag or branch moved.

We exercised the read-only self-bind in a private mount namespace.
Reads succeeded and writes failed with EROFS. `systemd-analyze verify` accepted
the actual mount unit. This is host mount evidence, not a guest boot claim.

Runtime evidence from `4e30385`: [production ISO run](https://github.com/tuna-os/tromso/actions/runs/41395837392)
passed its UEFI serial gate. That is not proof of a healthy desktop.
The downloaded production screenshot is black. The
[debug live screenshot](https://raw.githubusercontent.com/tuna-os/tromso/ci-screenshots/luks-e2e/41395843658/stable/live-boot.png)
shows the installer, but also missing glyphs and a black desktop.
It uses the older published payload, not the new candidate.

[Both install tests](https://github.com/tuna-os/tromso/actions/runs/41395843658)
accepted the immutable media and reached bootc, then failed with a splitstream
EOF. The other jobs in that Test run passed.

The [prepared-payload rerun](https://github.com/tuna-os/tromso/actions/runs/41447171165)
completed both installs. LUKS accepted the passphrase and reached a login screen.
Its [actual frame](https://raw.githubusercontent.com/tuna-os/tromso/ci-screenshots/luks-e2e/41447171165/stable/final-boot.png)
shows boxes in place of letters and the old theme, not the new identity.

Plain reached a login prompt, but its gate waited for a display-manager message
absent from serial output. The new gate recognizes getty but still needs a stable
frame. The [rerun](https://github.com/tuna-os/tromso/actions/runs/41454608790)
succeeded in every job of the Test workflow.

Its [plain frame](https://raw.githubusercontent.com/tuna-os/tromso/ci-screenshots/plain-e2e/41454608790/stable/final-boot.png)
and [encrypted frame](https://raw.githubusercontent.com/tuna-os/tromso/ci-screenshots/luks-e2e/41454608790/stable/final-boot.png)
show the installed login screen. The text has boxes in place of letters.
Both frames use the old theme. These are from the old published payload,
not the current candidate.

The [corrected ISO](https://github.com/tuna-os/tromso/actions/runs/41447164858)
booted through UEFI and waited for a stable GUI. Its actual
[screenshot](https://github.com/tuna-os/tromso/actions/runs/41447164858/artifacts/13144831230)
shows a readable installer. KDE titles and the panel use boxes in place of
letters. The desktop is black, with a red error icon. This frame uses the older
published payload, not the new candidate.

The [`virtio-vga` ISO run](https://github.com/tuna-os/tromso/actions/runs/41462038652)
also booted through UEFI. It reached the ready token after 30 seconds and then
waited for a stable frame. We downloaded and read its
[actual screenshot](https://github.com/tuna-os/tromso/actions/runs/41462038652/artifacts/13153670942).
The same KDE text and desktop defects remain.

The [Test run](https://github.com/tuna-os/tromso/actions/runs/41462097232) passed
every job, with real plain and LUKS installs. We also read both installed frames.
They still show the old login screen and boxes in place of letters.
Both runs use the older payload at digest `2b89f634`, not the current
candidate. The GPU change does not prove a fix for fonts or the new identity.

The shared prose tool at `7c070815` now reports zero findings in its full scan.
We corrected the 494 inherited findings across eight files. We did not add
opt-outs or increase the budget, which remains zero.

## Channels: nightly (main) and stable

- **main** is the nightly trunk: the daily scheduled multi-runner build
  publishes `:latest`, `:nightly`, `:nightly-YYYYMMDD`, `:<sha>`; the ISO
  lands at R2 `tromso/`.
- **stable** is a release bookmark branch.
  A weekly schedule or manual dispatch starts `promote-stable.yml`.
  A manual run defaults to `dry_run=true`.
  It copies the qualified digest to `:stable` and `:stable-YYYYMMDD`.
  Then it moves the branch and starts only the ISO job, not another OS build.
  The stable ISO embeds an offline payload and keeps `:stable` for updates.
- Update PRs from source trackers or Renovate target only main. Stable moves
  only through promotion.

Promotion passes the verified digest as `payload_ref` to the ISO job.
It passes `:stable` separately as `update_ref`.
The ISO job uses that digest if the stable tag changes while it waits.
The local recipe uses `TUNA_UPDATE_REF` for the same separation.

Before a tag moves, the workflow checks the image revision and publisher signature.
The certificate must name the same source commit.
ISO, plain and LUKS artifacts must qualify that exact image digest.
`force=true` can ignore workflow status, but not image identity or evidence.

Each successful ISO or install check records its pinned image.
Its `qualification-*` artifact also names the workflow SHA and run ID.
Promotion checks these fields against the GitHub run, not only a green status.
Old runs without this evidence cannot authorize a new promotion.
The artifacts remain available for 14 days.


## Release-linked sources

Local elements use upstream **release tags** (globs such as `v[0-9]*`) instead
of development branches. Thus, the daily `bst source track` selects releases.
Some content repositories use branches, such as aurora common, docs,
wallpapers, and the xfwl4 development repositories. Junctions also use a fixed
branch. Do not set `track:` to one exact tag, because the tracker cannot move it.

## Guard rails (what stops a bad commit)

Branch protection on main needs pre-merge checks. These checks include
shellcheck, yamllint, actionlint, BATS, pytest, the luks-unlock suite,
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

### Pull request CI (`test.yml`)

All pre-merge checks are in one workflow, `test.yml`. Its `changes` job lists
the changed files and starts only the jobs that those files can affect. A
skipped job reports success, so each required check always reports. If the
`changes` job fails, all checks run. A change to `test.yml` runs all checks.

| Job | Runs when the change touches |
|-----|------------------------------|
| shellcheck | `*.sh`, `*.bash` |
| yamllint | `*.yml`, `*.yaml` |
| actionlint | `.github/workflows/`, `.github/actions/` |
| Renovate Config Validate | `renovate.json` |
| lint .bst files | `*.bst` |
| BuildStream Validate | a file outside docs, tests, scripts, `tromso/`, `.github/` and the justfiles |
| BATS Unit Tests | `tests/bats/`, `tromso/src/` |
| Python Tests | a file that is not `*.md` or `LICENSE*` |
| Just Parse | `Justfile`, `iso.justfile`, `just/` |

The plain and LUKS install tests build the same ISO and use different install
paths. A change to their shared inputs (`tromso/`, the justfiles,
`scripts/lib-install-qemu.sh`, `scripts/embed-oci-payload.sh`,
`scripts/prepare-payload.sh`) runs one of
the two tests. The run number selects the test. Set the repository variable
`E2E_ROUND_ROBIN_SIZE` to 2 to run both. A change to the install script or
workflow of one test always runs that test. The two tests run fully on their
weekly schedules and on manual dispatch.

The tests execute the installer from the ISO. They do not replace that binary
or repair the hostname or LUKS arguments after installation. Only console
arguments change so the test can observe the installed boot on serial.

## Rollback

`rollback-stable.yml` runs only after a manual dispatch, and `dry_run` defaults
to true. It checks the target commit, image revision and publisher signature.
It uses the same keyless trust policy as promotion.

Then, `skopeo copy --preserve-digests` puts the original digest on `:stable`
and a dated `stable-rollback-*` tag. The workflow checks the target digests.
It moves the stable branch to the same source commit without an OS build.
Promotion and rollback cannot run at the same time.

This workflow restores only the x86_64 image tag and the git branch.
It does not change the `-aarch64` tags or the R2 ISO.
An existing ISO keeps its payload after a tag moves.
Restore the ISO objects separately if that payload is bad.
The [rollback runbook](../runbooks/rollback-a-bad-stable-release.md) gives the
manual steps for other artifacts and the final verification.
