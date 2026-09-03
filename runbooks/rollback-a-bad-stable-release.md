# Runbook: roll back a bad `stable` release

**Applies to:** `ghcr.io/tuna-os/tromso` stable tags, the R2 `tromso/stable/`
ISO surface, and the `stable` git branch.

**Scope note:** as of this writing the stable channel has never been cut —
there is no `stable` branch, `Build and Publish Tromsø Live ISO` has no
successful run, and `Promote main to stable` has failed on every weekly cron
since 2026-08-04. This runbook is written for the first release and after,
and it documents the surfaces automation does *not* currently restore.

## 1. What a stable release publishes

One promotion (`promote-stable.yml` → `build-tromso-multirunner.yml` on the
`stable` branch → `build-iso.yml` via `workflow_run`) moves all of these:

| Surface | Ref | Moved by |
| --- | --- | --- |
| x86_64 image | `ghcr.io/tuna-os/tromso:stable`, `:stable-YYYYMMDD`, `:<sha>` | multirunner `build_final` |
| aarch64 image | `:stable-aarch64`, `:stable-YYYYMMDD-aarch64`, `:<sha>-aarch64` | multirunner aarch64 job |
| Live ISO | R2 `tromso/stable/tromso-live-latest.iso` + `tromso-live-<date>-<sha7>.iso` (+ `-CHECKSUM`, `.sig`, `.cert`) | `build-iso.yml` |
| Git bookmark | branch `stable` | `promote-stable.yml` |

`rollback-stable.yml` restores **only the x86_64 `:stable` tag and the git
branch**. The aarch64 tags and the whole ISO surface must be restored by
hand — sections 4 and 5.

## 2. Decide what is actually broken

The ISO embeds `ghcr.io/tuna-os/tromso:stable` as its payload
(`build-iso.yml` rewrites `tromso/payload_ref` per channel), so the two
failure modes need different responses:

- **Installed system is bad** (bad package, broken boot after install):
  the image rollback in section 3 is sufficient. The published ISO keeps
  working because it resolves `:stable` at install time.
- **Live environment is bad** (ISO does not boot, installer does not launch,
  no `TROMSO_LIVE_READY` marker): the image rollback fixes nothing for
  downloaders. You must restore the ISO objects — section 5.

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

Then re-run with `dry_run=false`. It `skopeo copy --preserve-digests` the
target onto `:stable` plus a dated `stable-rollback-*` tag, and force-pushes
`stable` to the same commit.

**Verify the signature before you trust the rolled-back image** — the
workflow does not (its header comment saying "no cosign yet" is stale;
`build-tromso-multirunner.yml` has signed every pushed digest since the
cosign step landed):

```
cosign verify ghcr.io/tuna-os/tromso:stable \
  --certificate-identity-regexp '^https://github.com/tuna-os/tromso/' \
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

# 2. Promote it back over the mutable "latest" name, with its signature.
GOOD=tromso-live-<date>-<sha7>.iso
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso"
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}.sig" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso.sig"
rclone copyto "R2:${R2_BUCKET}/tromso/stable/${GOOD}.cert" \
              "R2:${R2_BUCKET}/tromso/stable/tromso-live-latest.iso.cert"
```

Do not delete the bad dated ISO: keep it for the postmortem, and its dated
name is not what anyone downloads.

**Caveat on identifying the good ISO by name.** The dated filename is built
from `github.sha` (`build-iso.yml`, "Compute ISO name"), but the ISO build's
usual trigger is `workflow_run`, where `GITHUB_SHA` is documented as the last
commit on the *default* branch — not the commit that was built. (The checkout
step in the same workflow compensates with
`github.event.workflow_run.head_sha || github.sha`; the naming step does
not.) So for stable ISOs the `<sha7>` in the filename generally names a
`main` commit, not the stable commit inside the image. Confirm the candidate
by run timestamp and by the `Build and Publish Tromsø Live ISO` run's
artifacts, not by the SHA in the name.

## 6. Verify the rollback

```
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable --format '{{.Digest}}'
skopeo inspect docker://ghcr.io/tuna-os/tromso:stable-aarch64 --format '{{.Digest}}'
git ls-remote --heads https://github.com/tuna-os/tromso stable
curl -sI https://download.tunaos.org/tromso/stable/tromso-live-latest.iso
cosign verify-blob --signature tromso-live-latest.iso.sig \
  --certificate tromso-live-latest.iso.cert \
  --certificate-identity-regexp '^https://github.com/tuna-os/tromso/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  tromso-live-latest.iso
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
