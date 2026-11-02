# KDE community announcement kit

Issue: [#365](https://github.com/tuna-os/tromso/issues/365).
Status: drafts for maintainer review; maintainers have posted no external announcement.

## Announcement / editorial pitch

Subject: Meet Tromso: a community KDE Plasma 6 OCI/bootc desktop project

Hello KDE community,

We introduce [Tromso](https://github.com/tuna-os/tromso), a TunaOS community
project. It builds KDE Plasma 6 with BuildStream on freedesktop-sdk.
It builds bootable OCI images for bootc. Tromso is independent, with no claim
of KDE endorsement or status as an official variant of KDE Linux.

Our focus is the Plasma desktop, source-based image composition, and updates
through system images. One repository contains KDE package definitions, OCI
composition, and live ISO tools. The approach draws on Project Bluefin Dakota
and GNOME OS build patterns.

The [multi-runner pipeline](https://github.com/tuna-os/tromso/actions/workflows/build-tromso-multirunner.yml)
splits the graph into chunks. It merges their content-addressed artifacts
before final image composition. Publication uses cosign to sign through
GitHub Actions OIDC. The
[README](https://github.com/tuna-os/tromso#verifying-signatures) documents the
expected signer identity and verification commands. These describe the build
and verification design. They do not guarantee that every run publishes an image.

Tromso remains Alpha under its
[roadmap](https://github.com/tuna-os/tromso/blob/main/ROADMAP.md).
Release gates cover builds, installation, release operations, user guidance,
and desktop validation. Consult the roadmap and linked runs for current
evidence before you test an artifact. This introduction invites collaboration;
it does not announce a stable release.

We welcome feedback from Plasma packagers and developers of image-based desktops.
Which smoke tests would help most? Where can our package definitions help
other community efforts? Report Tromso-specific problems in
[our issue tracker](https://github.com/tuna-os/tromso/issues).

- [Project overview and build instructions](https://github.com/tuna-os/tromso#readme)
- [Pipeline and ISO documentation](https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md)
- [Contribution guide](https://github.com/tuna-os/tromso/blob/main/CONTRIBUTING.md)

Thank you for the desktop on which this work depends.

## Short forum / Invent cross-post

Title: Tromso: KDE Plasma 6 with BuildStream and bootc

Tromso is a TunaOS community project. It builds KDE Plasma 6 on freedesktop-sdk
with BuildStream and targets OCI/bootc system images. Its repository includes
multi-runner builds, keyless signature configuration, and live ISO tools.
It is independent of KDE's official Linux project and remains Alpha.
Read the roadmap and current build evidence before you test it.

We welcome feedback on Plasma smoke tests and opportunities to share package
definitions for BuildStream. Overview, build instructions, and contribution
links: https://github.com/tuna-os/tromso#readme

Release gates: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md

Tromso-specific reports: https://github.com/tuna-os/tromso/issues

For cross-posts, add the canonical announcement URL so readers can follow
discussion across channels.

## Evidence and publication checklist

A maintainer should review the final copy and act as the public contact before
publication. Record the sender and publication URLs in #365. This kit alone
does not complete publication.

- Reconcile the README's functional-desktop claim with the roadmap's Alpha gates.
  Claims of maturity or verified boot need a successful run URL, candidate
  commit/digest, and tested configuration.
- Check the [build workflow](../../.github/workflows/build-tromso-multirunner.yml),
  [ISO workflow](../../.github/workflows/build-iso.yml), and
  [pipeline guide](../ci-and-iso-pipeline.md) against the final copy.
  Verify availability and signatures before you add links to exact artifacts.
- Use Plasma 6 in the copy. More specific versions need evidence from shipped
  packages and a desktop smoke test. Avoid date-based claims about upstream
  releases or enterprise adoption.
- For KDE News/editorial coverage, ask the
  [KDE press contact](https://kde.org/contact/) for the appropriate submission route.
  Do not assume the old KDE.News site accepts submissions.
- For community discussion, use [KDE Discuss](https://discuss.kde.org/).
  Check the scope and current rules of its Community and Announcement categories.
- Confirm the KDE-Linux SIG's preferred channel with participants before you post.
  Consult the [KDE list directory](https://mail.kde.org/mailman/listinfo/)
  and [kde-community scope](https://mail.kde.org/mailman/listinfo/kde-community).
  Do not assume a SIG address or use an unrelated list.
- Cross-post to KDE Invent only where the project has asked
  for community announcements. Confirm the venue first. Do not create unrelated code issues
  to promote Tromso. Use the short copy and canonical announcement URL.
- Add `https://docs.tunaos.org` only after maintainers review the live matrix
  page for Tromso variants. Link its exact page. Until then, use the repository
  docs above without placeholder links in the announcement.
- Record live URLs and moderation status in #365. Keep it open until publication
  and record the outcome of each intended cross-post.
