# Maintaining Tromsø

This guide is for a maintainer on the first day. It tells you where things
are, how a change gets to users, what you can merge, and what you must not
merge without proof. For more detail, each section names its source document.

## The repository in one page

| Path | Contents |
|---|---|
| `elements/` | All BuildStream elements. `elements/kde/` is Plasma and Qt, `elements/tromso/` is the Tromsø layer, `elements/oci/` assembles the image. |
| `elements/freedesktop-sdk.bst` | The junction that supplies the base system. |
| `elements/kde-buildstream.bst` | A pinned junction to the official KDE BuildStream recipes. No element uses it yet. |
| `files/`, `patches/`, `include/` | Files that the elements install, source patches, and shared YAML (aliases, mirrors). |
| `tromso/` | The live ISO: `Containerfile`, live-session setup, the dracut module. |
| `Justfile`, `iso.justfile`, `just/` | All commands. Run BuildStream only through `just bst`. |
| `scripts/` | Shell and Python helpers for CI and for the install tests. |
| `tests/pytest/`, `tests/bats/` | Fast tests of the source tree. They need no build. |
| `.github/workflows/` | CI. The table below lists the workflows that matter. |
| `docs/`, `runbooks/` | Design, pipeline guide, decision records, and the rollback runbook. |

Read these next: `AGENTS.md` for the build rules,
[the pipeline guide](ci-and-iso-pipeline.md) for CI, and
[the architecture overview](ARCHITECTURE.md) for the design.

## How a change gets to users

1. **Pull request.** `test.yml` runs the pre-merge checks. Seven of them are
   required: `shellcheck`, `yamllint`, `actionlint`, `BATS Unit Tests`,
   `Python Tests`, `BuildStream Validate`, and `Just Parse`. These checks read
   the source tree.
   They do not build or boot the image.
2. **Nightly build.** `build-tromso-multirunner.yml` runs at 00:30 UTC and on
   manual dispatch. It is the only workflow that builds and publishes the
   image. A reusable workflow in `tuna-os/bst-ci` plans the build and builds a
   core stage and ten chunk stages. `build-final.yml` assembles, exports and
   pushes the image to `ghcr.io/tuna-os/tromso`. The `sign_final` job signs
   the digest with cosign and records a release candidate.
3. **Live ISO.** A successful nightly build starts `build-iso.yml`. It builds
   the ISO, boots it in QEMU, and waits for the `TROMSO_LIVE_READY` marker.
   It does not sign or upload that ISO. The `publish` job signs and uploads
   the ISO after that boot. Only a manual dispatch of `build-iso.yml` on
   `main` with `skip_upload` off runs it.
4. **Install tests.** `test-plain-install.yml` and `test-luks-install.yml`
   install from the ISO to a virtual disk and boot the result.
5. **Stable.** `promote-stable.yml` selects one signed candidate from main. It
   builds the ISO and runs both install tests on that candidate. Then it
   copies the same digest to `:stable`. `rollback-stable.yml` moves `:stable`
   back. No other workflow writes the stable channel.

The build cache is on GHCR as `cache-tromso-core` and `cache-tromso-<chunk>`.
Each stage restores it, builds, and pushes it again. A stage that runs out of
time still pushes its cache, so the next run continues from there.

`staleness-check.yml` opens an issue when main has no successful build for 48
hours. Look for that issue first each day.

## Review rules

Read the full diff and the result of `gh pr checks`. Then use these rules.

### What you can merge on green checks

- Documentation, tests, and scripts that only tests use.
- Workflow changes that make a gate stricter, when a test in `tests/pytest/`
  holds the new behavior.
- Pull requests from Renovate and from the source tracker (see below).

### What needs a booted proof

Pull request CI does not build the image. A green check does not show that
the image boots. Do not merge these changes without a booted proof:

- a change to `elements/tromso/system-config.bst`, PAM files, `sshd`, SDDM,
  polkit, sudoers, or systemd units;
- a change to `elements/oci/` or to the kernel, initramfs, bootloader, or
  bootc elements;
- a change to `tromso/` or to the installer recipe that changes the live
  session or the install;
- an update of the `freedesktop-sdk` junction.

A booted proof is one of these:

- a nightly build with a passed ISO boot gate;
- a passed plain or LUKS install run;
- a local boot with `just boot-vm`, with a screenshot or serial log in the
  pull request.

When the nightly build fails, no proof is possible. Then repair the nightly
build first.

### What you must never merge

- A change that makes a signature weaker. The signatures come from the
  `sign_final` job and the cosign steps in `build-iso.yml`. The verify
  commands in `README.md` name the trusted identity.
- A second writer for `:stable` or for the stable ISO.
- A publication step that runs before its boot gate, or one with
  `continue-on-error`.
- A gate wrapped in `|| echo` or `|| true`.
- A `paths:` filter on a workflow that has a required check.
- A pre-built binary in place of a source build. `AGENTS.md` gives the reason.
- A change to `/etc/containers/policy.json` that accepts more than before.
  Issue #478 tracks the approved plan to verify signatures on update.

When you are not sure, request changes and say what proof you need.

### How to merge

The repository has no merge queue. Use squash merge for one pull request.

Many pull requests add a row at the top of the same table in the pipeline
guide. After one of them merges, the others are in conflict. Do not push to a
branch of a contributor. Ask for a rebase.

As an alternative, make a branch
that merges the reviewed heads without change, and resolve the conflicts
there. Merge that branch with a merge commit. GitHub then marks each original
pull request as merged. Pull request #515 is an example.

## Pull requests from the source tracker

Renovate cannot read `.bst` files. `track-bst-sources.yml` runs
`bst source track` each day for `elements/tromso`. It keeps one pull request
open from the `auto/track-elements` branch. The title is
`chore(deps): track element sources`.

- A second group, `kde-frameworks`, tracks `elements/kde/frameworks` and
  opens `auto/track-kde-frameworks` titled
  `chore(deps): track KDE Frameworks sources`. Do not automerge it. Merge only
  after green CI, a full image build and a boot proof. Plasma and
  Applications are not tracked until Qt 6.11 lands (#534).
- Read the diff. It must change only `ref:` lines.
- Two elements track a branch of a different project:
  `elements/tromso/bluefin-common.bst` and `elements/tromso/image-overlay.bst`.
  A new ref can add files to the image. Open the upstream compare view for
  the two refs before you merge.
- Merge on green checks. If the next nightly build fails in a tracked element,
  revert the bump.
- Renovate updates the Actions and the container tags. After a change to a
  `uses:` line, `actions.lock` must change in the same pull request.

## Who owns what

`.github/CODEOWNERS` gives @hanthor the paths with security risk: `.github/`,
container files, sudoers, polkit rules, `sshd_config`, and cosign files. Pull
request #514 made this list small on purpose. All other paths have no code
owner, so a maintainer or the hive can review them.

| Area | Owner today |
|---|---|
| Signing keys, repository secrets, R2 bucket, branch protection | @hanthor |
| Release decisions: promotion to stable, rollback | @hanthor |
| Shared build workflow | `tuna-os/bst-ci`. Its pin in `build-tromso-multirunner.yml` moves by Renovate. |
| Elements, live ISO, install tests, docs | open; tell us what you want to own |

## Where the hive agents fit

The hive is a set of AI agents that work on this repository. You see them as
the account `hanthor-hive-agent` and as labels.

- Agents open issues. The label `agent/<name>` shows which agent wrote it.
- `stage/...` labels show progress, for example `stage/040-covered-by-pr` and
  `stage/072-returned-to-contributor`.
- Some issues need a choice from a person and give options. Reply with
  `/hive approve` or `/hive decision <letter>`. The issue then gets the
  `approved-direction` label. Check that label before you review a pull
  request for that issue: the pull request must follow the approved option.
- The hive puts `sentinel-alert` on a pull request that changes a workflow, a
  policy, or a security document. The hive does not approve or merge such a
  pull request. A maintainer must review it.
- The hive cannot push to a fork. A pull request from a fork that is in
  conflict waits for its author.
- Contributors can also donate compute. `CONTRIBUTING.md` has the link.

An agent review is input. It is not an approval. The merge decision is yours.

## Upstream alignment

KDE Linux has official BuildStream recipes on `invent.kde.org`. Tromsø moves
toward them, and toward `projectbluefin/dakota`, in small steps.
[The alignment plan](UPSTREAM-ALIGNMENT.md) has the survey and the steps.
Issue #521 tracks the work, and each step has its own issue (#525 to #537).

- `elements/kde-buildstream.bst` came with pull request #524. It is a pinned
  junction that no element uses, so it does not change the image.
- A step that changes a junction or replaces local elements changes many
  cache keys. Such a step needs a full build and a booted proof.

## Local build

A build of `oci/tromso.bst` from an empty cache takes many hours. Copy the
CI cache first:

```bash
just bootstrap-cache
just cache-status
just build-local elements-you-changed.bst
```

`just bootstrap-cache` downloads the core cache from GHCR without a login and
checks its digest. After that, BuildStream rebuilds only what you changed.
Use this to test an element change before you ask for a nightly build. The
pipeline guide has the details in "Local builds from the CI cache".

## Your first week

1. Read `AGENTS.md` and [the pipeline guide](ci-and-iso-pipeline.md).
2. Run `just test`. It needs `bats` and `pytest`.
3. Open the last run of the nightly build and read which stage failed.
4. Review a small pull request and merge it.
5. Read [the rollback runbook](../runbooks/rollback-a-bad-stable-release.md).
   Start `rollback-stable.yml` once with `dry_run` set to true.
6. Review a pull request from the source tracker with the steps above.
7. Read [the alignment plan](UPSTREAM-ALIGNMENT.md) and choose one step issue
   of #521.
8. Tell @hanthor which area you want to own. Add yourself to the owner table
   in this file.
