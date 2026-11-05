# Runbook: roll back a bad `stable` release

A stable release moves the x86_64 GHCR image, optionally the aarch64 image,
the signed ISO objects in R2 `tromso/stable/`, and the `stable` git branch.
`rollback-stable.yml` restores these surfaces, with verification before any
mutation and a dry run by default. It shares the promotion concurrency lock.

## 1. Contain and choose targets

Pause the promotion cron so it cannot overwrite the rollback:

```bash
gh workflow disable "Promote main to stable" --repo tuna-os/tromso
```

Find a previously good image commit and dated ISO. The ISO can be a different
release if the live environment and installed payload need different fixes.
Dated objects are retained for investigation and future rollback.

```bash
gh run list --repo tuna-os/tromso \
  --workflow "Build Tromso (Multi-Runner)" --branch stable --status success
rclone lsl "R2:${R2_BUCKET}/tromso/stable/"
```

Configure rclone with the repository's R2 credentials before using it locally.
Never put credentials in an issue or workflow input. For ISOs published before
#286, filenames may identify the default branch rather than the actual build
commit: confirm provenance using the original workflow run and artifacts.

## 2. Verify without changing anything

```bash
gh workflow run "Rollback :stable" --repo tuna-os/tromso \
  -f target_sha=<full-known-good-sha> \
  -f target_iso=tromso-live-<date>-<sha7>.iso \
  -f reason="<incident link>" -f dry_run=true
```

The workflow requires a commit in this repository, resolves its image digest,
and verifies its cosign signature against the multirunner workflow identity.
It downloads the dated ISO, checksum, signature and certificate from R2, then
checks the checksum and verifies the blob against the ISO workflow identity.
Missing or invalid targets stop the workflow before it moves anything.

The workflow restores aarch64 by default, requiring a signed
`:<target_sha>-aarch64` image and restoring that tag and its dated rollback
bookmark along with x86_64. The aarch64 build is experimental and opt-in:
if the affected release did not publish it, explicitly add
`-f rollback_aarch64=false`. Read the summary to confirm the selection.

## 3. Apply and verify

Repeat the verified dispatch with `-f dry_run=false`. It copies verified
image digests onto the selected stable and dated rollback tags, checks the
destination digests, restores all four mutable R2 objects (ISO, `.sig`, `.cert`,
and `-CHECKSUM`), and finally moves the `stable` branch to `target_sha`.

R2 restore verifies the dated objects again before writing. It regenerates
the checksum with the mutable filename and reads back all four destinations
to compare bytes. Copy failures and mismatches fail the workflow. R2 has no
transaction across objects: a partial copy can leave mixed sidecars. Keep
promotion paused and rerun the same verified rollback after fixing the error.
The branch moves only after both image and R2 steps succeed.

Verify the public CDN surface as well as the workflow result:

```bash
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable --format '{{.Digest}}'
# If selected:
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable-aarch64 --format '{{.Digest}}'
git ls-remote --heads https://github.com/tuna-os/tromso stable
for suffix in '' .sig .cert -CHECKSUM; do
  curl --fail --location --output "tromso-live-latest.iso${suffix}" \
    "https://download.tunaos.org/tromso/stable/tromso-live-latest.iso${suffix}"
done
sha256sum --check tromso-live-latest.iso-CHECKSUM
cosign verify-blob --signature tromso-live-latest.iso.sig \
  --certificate tromso-live-latest.iso.cert \
  --certificate-identity-regexp '^https://github\.com/tuna-os/tromso/\.github/workflows/build-iso\.yml@refs/heads/(main|stable)$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  tromso-live-latest.iso
```

An installed system picks up the restored image on its next `bootc upgrade`.
`bootc rollback` on a user's machine is independent of this release operation.

## 4. Close out

Record the incident and restored refs in `docs/ci-and-iso-pipeline.md`.
Land the fix on `main`, then re-enable promotion:

```bash
gh workflow enable "Promote main to stable" --repo tuna-os/tromso
```

Failed promotion runs create a GitHub issue linking to the failed run. Inspect
which steps ran before retrying, and close the alert after resolving it.
