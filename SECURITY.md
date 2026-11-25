# Security Policy

## Supported Versions

Tromso images are built from `main` each day at 00:30 UTC, or on manual dispatch,
and published to GHCR.
Only the most recent build of each tag has active support.

| Tag | Status |
|---|---|
| `latest` | ✅ Supported |
| `<git-sha>` | ⚠️ Best effort |
| `nightly-<YYYYMMDD>` | ⚠️ Best effort |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, report them privately via GitHub Security Advisories:

1. Go to the [Security tab](https://github.com/tuna-os/tromso/security)
2. Click **Report a vulnerability**
3. Provide a detailed description of the issue, including steps to reproduce

You can expect:
- **Acknowledgment** within 48 hours
- **Status update** within 5 business days
- **Resolution timeline** based on severity

## Security Model

Tromso images are:
- Built in CI from fixed BuildStream elements with a content-addressed cache
- Published as OCI images to `ghcr.io/tuna-os/tromso`
- Built inside a pinned `bst2` container with local CASD

## Supply Chain Security

- Git references or SHA256 values for tarballs fix the base elements in the `elements/` tree.
  See `AGENTS.md` for the paths. The project removed the former `kde-build-meta`
  junction and moved its elements into this repository.
- The `elements/freedesktop-sdk.bst` junction fixes the version of the `freedesktop-sdk` base SDK.
- The content-addressable CASD store of BuildStream resolves build dependencies.
- A digest fixes the version of the build container (`bst2`).

## Secure Boot Signing Key

The tunaOS Secure Boot key signs systemd-boot and the kernel in the publish
job. The secrets are `TUNAOS_SB_KEY` and `TUNAOS_SB_CERT`.

- The key belongs in the GitHub environment `secure-boot-signing`. The
  branch policy of that environment admits `main` only. A workflow on any other branch cannot read an environment secret.
- Only the `build_final` job of `build-final.yml` names that environment. A
  test fails if another job reads the two secrets.
- State on 2026-11-25: the environment exists, but the two secrets are still
  organisation secrets. The owner must run `tunaos-secure-boot-lockdown.sh`
  with the key file. The script sets the environment secrets and deletes the
  organisation secrets. Until then, a workflow on a branch can read the key.

See [`docs/secure-boot.md`](docs/secure-boot.md) for the details and the
limits.

## Disclosure Policy

We follow coordinated disclosure:
1. The reporter submits a vulnerability through a private channel.
2. We investigate and develop a fix.
3. We deploy the fix to new builds.
4. We publish an advisory after deployment.

See `AGENTS.md` and `SPEC.md` for full build architecture details.
