# Security Policy

## Supported Versions

Aurora Tromso images are built on every push to `main` and published to GHCR.
Only the most recent build of each tag is actively supported. Older tags are
pruned periodically.

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

Aurora Tromso images are:
- Built in CI from pinned BuildStream elements with content-addressed caching
- Published as OCI images to `ghcr.io/tuna-os/tromso`
- Built inside a pinned `bst2` container with local CASD

## Supply Chain Security

- Base elements are pinned by junction refs in `elements/kde-build-meta.bst`
- Build dependencies are resolved via BuildStream's CASD content-addressable store
- KDE package definitions live in `hanthor/kde-build-meta` with pinned junction URLs
- The build container (`bst2`) is pinned by digest

## Disclosure Policy

We follow coordinated disclosure:
1. Reporter submits vulnerability privately
2. We investigate and develop a fix
3. Fix is deployed to new builds
4. Advisory is published after deployment

See `AGENTS.md` and `SPEC.md` for full build architecture details.
