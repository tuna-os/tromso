# Runbook: roll back a bad `stable` release

**Applies to:** `ghcr.io/tuna-os/tromso` stable tags, the R2 `tromso/stable/`
ISO surface, and the `stable` git branch.

This health work does not establish a qualified stable release.
A green build alone is not enough. Before promotion, check the actual ISO,
plain and LUKS evidence for the same signed image digest.

## 1. What a stable release publishes

Promotion reuses a qualified image digest and starts only the stable ISO job.
It does not build the OS again.

| Surface | Ref | Moved by |
| --- | --- | --- |
| x86_64 image | `ghcr.io/tuna-os/tromso:stable`, `:stable-YYYYMMDD` | `promote-stable.yml` copies the signed `:<sha>` digest |
| aarch64 image | `:stable-aarch64`, `:stable-YYYYMMDD-aarch64`, `:<sha>-aarch64` | experimental manual multirunner build; not part of x86_64 promotion |
| Live ISO | R2 `tromso/stable/tromso-live-latest.iso` and dated ISO, checksum and `.bundle` | `build-iso.yml` |
| Git bookmark | branch `stable` | `promote-stable.yml` |

`rollback-stable.yml` restores **only the x86_64 `:stable` tag and the git
branch**. The aarch64 tags and the whole ISO surface must be restored by
hand — sections 4 and 5.

## 2. Decide what is actually broken

The ISO embeds one immutable offline payload. The installed system keeps
`:stable` as its update reference. Moving that tag does not change an ISO
that a user has already downloaded.

- **Installed system is bad:** roll back the image in section 4.
  Also restore the published ISO if its embedded payload is bad.
- **Live environment is bad:** restore the ISO objects in section 5.
  A tag rollback alone does not change the live environment.

## 3. Contain first

Pause the promotion cron before anything else, or the next Tuesday 09:00 UTC
run can promote straight back over your rollback:

```
gh workflow disable "Promote main to stable" --repo tuna-os/tromso
```

Re-enable it only after the cause is fixed on `main`.

## 4. Roll back the image and the branch

Find a candidate commit that has a published image:

```
gh run list --repo tuna-os/tromso \
  --workflow "Build Tromso (Multi-Runner)" --branch stable --status success
gh api "orgs/tuna-os/packages/container/tromso/versions" \
  --jq '.[] | {updated_at, tags: .metadata.container.tags}'
```

Dry-run first (the workflow defaults to `dry_run: true` — leave it true on
the first pass and read the digests it prints):

```
gh workflow run "Rollback :stable" --repo tuna-os/tromso \
  -f target_sha=<full-sha> -f reason="<incident link>" -f dry_run=true
```

Then re-run with `dry_run=false`. The workflow first checks the source commit,
image revision and the keyless signature from the publisher.
It copies that exact digest onto `:stable` and a dated `stable-rollback-*` tag.
It checks both resulting digests, then moves `stable` to the same commit.

You can also verify the published tag with the same workflow identity and
GitHub issuer. Use the full expected source SHA:

```
cosign verify ghcr.io/tuna-os/tromso:stable \
  --certificate-identity-regexp '^https://github.com/tuna-os/tromso/\.github/workflows/build-tromso-multirunner\.yml@.*$' \
  --certificate-github-workflow-sha <full-sha> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

### aarch64 is not covered

`rollback-stable.yml` never touches the `-aarch64` tags, so `:stable-aarch64`
still points at the bad build after it runs. Restore it manually:

```
skopeo copy --preserve-digests \
  docker://ghcr.io/tuna-os/tromso:<target-sha>-aarch64 \
  docker://ghcr.io/tuna-os/tromso:stable-aarch64
```

## 5. Restore the ISO surface (manual)

Nothing in CI restores R2. Dated ISOs are never deleted, so the previous good
build is still there under its own name.

```
export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
       RCLONE_CONFIG_R2_REGION=auto
export RCLONE_CONFIG_R2_ACCESS_KEY_ID=... RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=... \
       RCLONE_CONFIG_R2_ENDPOINT=... R2_BUCKET=...

# 1. List what is there and pick the last known-good dated ISO.
rclone lsl "R2:${R2_BUCKET}/tromso/stable/"

# 2. Restore the bundle and checksum first; move the ISO alias last.
GOOD=tromso-live-<date>-<sha7>-<run>-<attempt>.iso
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}.bundle" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso.bundle"
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}-CHECKSUM" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso-CHECKSUM"
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso"
```

Do not delete the bad dated ISO: keep it for the postmortem, and its dated
name is not what anyone downloads.

The filename is not proof of the embedded image identity.
Check the `qualification-iso` artifact from the source run.
It records the actual pinned image reference, workflow SHA and run ID.
Older runs without that artifact need separate evidence before use.

## 6. Verify the rollback

```
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable --format '{{.Digest}}'
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable-aarch64 --format '{{.Digest}}'
git ls-remote --heads https://github.com/tuna-os/tromso stable
curl -sI https://download.tunaos.org/tromso/stable/tromso-live-latest.iso
digest=$(sha256sum -- tromso-live-latest.iso)
cosign verify-blob --bundle tromso-live-latest.iso.bundle \
  --certificate-identity-regexp '^https://github.com/tuna-os/tromso/\.github/workflows/build-iso\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "sha256:${digest%% *}"
```

All four digests/refs must name the target commit, the ISO URL must return
`200`, and the blob signature must verify. Nothing in CI checks the ISO URL,
so this `curl` is the only thing that catches a rollback that left the
download surface broken.

An existing user's machine only picks up the rolled-back image on its next
`bootc upgrade`; `bootc rollback` on the host is the per-machine lever and is
independent of this procedure.

## 7. Close out

- Record the incident and the restored refs in
  `docs/ci-and-iso-pipeline.md`'s troubleshooting table.
- Re-enable the promotion cron:
  `gh workflow enable "Promote main to stable" --repo tuna-os/tromso`.
- Land the fix on `main` and let a normal promotion move `stable` forward;
  do not hand-edit the `stable` branch.
