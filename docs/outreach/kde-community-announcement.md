# KDE community announcement kit

Issue: [#365](https://github.com/tuna-os/tromso/issues/365).
Status: drafts for maintainer review; no one has posted an external announcement.

## Announcement / editorial pitch

Subject: Introduce Tromso: a community project for a KDE Plasma 6 desktop with OCI/bootc

Hello KDE community,

We would like to introduce [Tromso](https://github.com/tuna-os/tromso), a
community project from TunaOS. It uses BuildStream to build a desktop with KDE
Plasma 6 on top of freedesktop-sdk. It targets bootable images in OCI format that bootc
manages. Tromso is independent. It claims no KDE endorsement or status as an
official variant of KDE Linux.

Our focus combines the Plasma desktop, source-based image composition, and
image-based system updates. The repository contains definitions for KDE
packages, OCI composition, and tooling for live ISOs in one place.
The approach draws on Project Bluefin Dakota and build patterns from GNOME OS.

The [multi-runner pipeline](https://github.com/tuna-os/tromso/actions/workflows/build-tromso-multirunner.yml)
splits the BuildStream graph into chunks and merges their content-addressed
artifacts before final image composition. The publication configuration uses
cosign for keyless signatures with OIDC from GitHub Actions. The
[README](https://github.com/tuna-os/tromso#verifying-signatures) documents the
expected signer identity and verification commands. These describe the build
and verification design. They do not guarantee that every run publishes an image.

Tromso remains Alpha in its
[roadmap](https://github.com/tuna-os/tromso/blob/main/ROADMAP.md). Build,
installation, release operations, user guidance, and desktop validation are
release gates. Please consult the roadmap and linked workflow runs for current
evidence before you use an artifact for tests. This introduction
invites collaboration. It does not announce a stable release.

We welcome feedback from packagers for Plasma and developers of image-based desktops.
Which smoke tests for the desktop would be most useful? Where can our
BuildStream package work help other community efforts? Please report
Tromso-specific problems in [our issue tracker](https://github.com/tuna-os/tromso/issues).

- [Project overview and build instructions](https://github.com/tuna-os/tromso#readme)
- [Pipeline and ISO documentation](https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md)
- [Contribution guide](https://github.com/tuna-os/tromso/blob/main/CONTRIBUTING.md)

Thank you for your work on the desktop on which this work depends.

## Short forum / Invent cross-post

Title: Tromso: explore KDE Plasma 6 with BuildStream and bootc

Tromso is a community project from TunaOS. It uses BuildStream to build a
desktop with KDE Plasma 6 on freedesktop-sdk. It targets OCI/bootc system
images. Its repository includes orchestration for multi-runner builds,
configuration for keyless signatures, and tooling for live ISOs.

It is independent of the official project for KDE Linux and remains Alpha.
Please read the roadmap and current build evidence before tests.

We would appreciate feedback on smoke tests for Plasma and opportunities to
share package work with BuildStream. Overview, build instructions, and
contribution links: https://github.com/tuna-os/tromso#readme

Release gates: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md

Tromso-specific reports: https://github.com/tuna-os/tromso/issues

When you cross-post, add the canonical URL for the announcement.
This lets readers follow discussion across channels.

## Evidence and publication checklist

A maintainer should review the final copy and act as the public contact before
they send it. Record the sender and publication URLs in issue #365.
Publication remains outstanding after maintainers merge this kit.

- Reconcile the README's functional-desktop claim with the roadmap's Alpha
  gates. Do not repeat the issue's claims of maturity or verified boot without evidence.
  This evidence must include a URL for a successful run, candidate commit/digest, and tested configuration.
- Check the [build workflow](../../.github/workflows/build-tromso-multirunner.yml),
  [ISO workflow](../../.github/workflows/build-iso.yml), and
  [pipeline guide](../ci-and-iso-pipeline.md) against the final copy. If you add
  artifact links, verify availability and signatures for that exact artifact.
- Keep the text at Plasma 6 unless evidence justifies a more specific version.
  This evidence must include shipped package versions and a smoke test for the desktop.
  Avoid date-based claims about upstream releases or enterprise adoption.
- For KDE News/editorial coverage, ask the
  [KDE press contact](https://kde.org/contact/) for the appropriate route for submissions now.
  Do not assume the old KDE.News site accepts submissions.
- For community discussion, use [KDE Discuss](https://discuss.kde.org/), whose
  Community and Announcement categories describe their scope. Choose the
  appropriate category under its current rules.
- Confirm the preferred channel for the KDE-Linux SIG with its participants
  before you post. The [directory of KDE email lists](https://mail.kde.org/mailman/listinfo/)
  and [kde-community scope](https://mail.kde.org/mailman/listinfo/kde-community)
  are initial references. Do not assume a SIG address or use an unrelated list.
- Cross-post to KDE Invent only where a relevant project has explicitly welcomed announcements from the community.
  Confirm the venue first. Do not create unrelated
  code issues to advertise. Use the short copy and canonical URL for the announcement.
- Add `https://docs.tunaos.org` only after the page for the Tromso variant matrix
  is live and has maintainer review. Link its exact page.
  Until then use the repository docs above.
  Do not put a placeholder link to documentation in the copy for publication.
- Record each live URL and any moderation status or status of approval requests in #365.
  Keep the issue open until the record accounts for publication and the intended cross-posts.
