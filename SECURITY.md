# Security Policy

## Supported Versions

Aurora Tromso images are built on demand and via CI. The image is published
as `ghcr.io/hanthor/tromso` with `latest`, date, and git-sha tags. Only the
most recent build is actively supported.

| Variant | Base | Status |
|---|---|---|
| Aurora Tromso | freedesktop-sdk + KDE Plasma 6 | ✅ Supported |

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
- Built with BuildStream from pinned source tarballs and git refs
- Composed as OCI images with cosign signing support
- Based on freedesktop-sdk, which provides audited base libraries and toolchain
- Build inside a pinned container image for reproducibility
- Published to GitHub Container Registry (GHCR)

## Supply Chain Security

- KDE packages built from source via `hanthor/kde-build-meta` (git-tag pinned refs)
- Base SDK from freedesktop-sdk (version-pinned junction)
- All third-party dependencies tracked via BuildStream element refs
- Container images signed with cosign
- CI runs in GitHub Actions with limited-scope tokens

## Disclosure Policy

We follow coordinated disclosure:
1. Reporter submits vulnerability privately
2. We investigate and develop a fix
3. Fix is deployed to new builds
4. Advisory is published after deployment

See [`SPEC.md`](SPEC.md) for full build architecture details.
