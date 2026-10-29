# Tromsø Roadmap

**Last updated**: 2026-10-24 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The workflows above are implemented. The first OCI push and a passing LUKS
run are now recorded, but ISO boot and plain-install validation remain open.
See [Release readiness](#release-readiness) for the current evidence.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates currently satisfied: 0 of 5.**

Each gate records whether its evidence has been produced, not whether the
machinery that would produce it exists. A row is only green when a run,
identified by URL, has passed.

| Gate | Required evidence | Current evidence (2026-10-24) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | ⚠️ First OCI publication achieved: [run 37128881064](https://github.com/tuna-os/tromso/actions/runs/37128881064/job/111275088334) built, linted and pushed the image, then failed signing. [PR #360](https://github.com/tuna-os/tromso/pull/360) merged the signing fix. [Latest build](https://github.com/tuna-os/tromso/actions/runs/40064106136) still failed; a successful scheduled candidate build remains required |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | ⚠️ Gate 2 is the immediate validation priority. Latest [ISO run](https://github.com/tuna-os/tromso/actions/runs/40077050721) skipped; [plain install](https://github.com/tuna-os/tromso/actions/runs/39398183219) failed; [LUKS install](https://github.com/tuna-os/tromso/actions/runs/39230716090) passed. These are separate runs, not evidence for one immutable candidate |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | ❌ Not demonstrated for a common candidate. Historical baseline (2026-09-02): promotion health checks failed on 7 of 7 scheduled runs. A non-forced promotion and rollback dry run still need linked evidence |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | ❌ Not met. Consumer guidance must distinguish published images from an install-validated release; publication alone does not establish supported installation instructions |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | ❌ Not met. Criteria and evidence record still need to be defined |

### Release readiness

The historical missing-image blocker has changed: the first OCI push succeeded
in run 37128881064 at commit `598a851e0072129bc6be04d87c3524bfb322a656`.
That run failed at signing, so publication must not be counted as a green
scheduled build. The signing fix merged as `923534a` ([#360](https://github.com/tuna-os/tromso/pull/360));
the OCI whiteout fix merged in [#361](https://github.com/tuna-os/tromso/pull/361).

Engineering triage should now establish Gate 2's runtime baseline rather than
assume every install failure is a missing image. [#369](https://github.com/tuna-os/tromso/issues/369)
tracks this shift. The LUKS success above is useful evidence, but neither a
moving `latest` tag nor independently scheduled runs prove a common candidate.

#### Gate 2 evidence handoff

A contributor attempted manual dispatch on 2026-10-24; the contributor write
gate rejected all three requests. No new validation runs were started. An
operator with Actions write access should run the following on upstream `main`:

```bash
gh workflow run build-iso.yml --repo tuna-os/tromso --ref main -f skip_upload=true
gh workflow run test-plain-install.yml --repo tuna-os/tromso --ref main
gh workflow run test-luks-install.yml --repo tuna-os/tromso --ref main
```

The ISO dry run avoids replacing the public R2 artifact while establishing the
baseline. Record each run URL, candidate source SHA, immutable payload digest,
installer channel, architecture, and boot/install result. The two E2E jobs use
the stable **installer** channel; this does not mean they validate a stable
Tromsø payload. Confirm the payload identity from the run evidence before
combining results. Classify failures by the first failing step and attach logs
and screenshots; keep ISO boot, plain install, and LUKS results separate.

Once all three pass for one candidate, verify `promote-stable.yml` preconditions
without forcing promotion: successful build, ISO boot, plain install and LUKS
runs, followed by the release-operations rollback evidence. Its current health
check compares recent completed runs independently, so the maintainer must
also verify candidate identity before a release decision. Gate 3 and Beta
remain closed until their own evidence is recorded.

### First Beta decision record

The first Beta promotion should publish a short decision record in the GitHub
Release notes containing:

- the candidate commit and immutable OCI digest;
- links to the build, ISO boot, plain-install, and encrypted-install evidence;
- the architectures and hardware/VM configurations actually tested;
- known limitations, support expectations, and rollback instructions; and
- the maintainer approving the promotion.

[#279](https://github.com/tuna-os/tromso/issues/279) tracks the first stable
candidate and replaces [#83](https://github.com/tuna-os/tromso/issues/83), which
was closed as completed on 2026-08-30 while none of the promotion it describes
had happened. The release decision must not be inferred from nightly freshness,
from a moving `latest` tag, or from the closure of a tracker.

### Keeping this file honest

Two rules apply to every change here:

1. A gate row cites run evidence — a passing run, or an explicit "never green"
   with the counts behind it. The existence of a workflow is not evidence that
   the gate is satisfied.
2. When an issue cited by a gate row is closed, that row is revisited in the
   same change that closes it. This file must never name a closed issue as a
   canonical tracker.

See [CI & ISO pipeline](docs/ci-and-iso-pipeline.md) for the implemented build,
publishing, promotion, and rollback architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
