# Security Policy

## Supported Versions

Tromso images are built on every push to `main` and published to GHCR.
Only the most recent build of each tag has active support. A periodic job
removes older tags.

| Tag | Status |
|---|---|
| `latest` | ✅ Supported |
| `<git-sha>` | ⚠️ Best effort |
| `<date>` | ⚠️ Best effort |

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

## Disclosure Policy

We follow coordinated disclosure:
1. The reporter submits a vulnerability through a private channel.
2. We investigate and develop a fix.
3. We deploy the fix to new builds.
4. We publish an advisory after deployment.

See `AGENTS.md` and `SPEC.md` for full build architecture details.
