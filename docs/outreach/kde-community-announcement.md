# KDE community announcement kit

Tracking: [#365](https://github.com/tuna-os/tromso/issues/365).
Status: drafts for maintainer review; no external announcement has been posted.

## Announcement / editorial pitch

Subject: Introducing Tromso: a community KDE Plasma 6 OCI/bootc desktop project

Hello KDE community,

We would like to introduce [Tromso](https://github.com/tuna-os/tromso), a
TunaOS community project building a KDE Plasma 6 desktop with BuildStream on
top of freedesktop-sdk, targeting bootable OCI images managed with bootc.
Tromso is an independent project, with no claim of KDE endorsement or official
KDE Linux variant status.

Our focus is the intersection of the Plasma desktop, source-based image
composition, and image-based system updates. The repository contains the KDE
package definitions, OCI composition, and live ISO tooling in one place. The
approach draws on Project Bluefin Dakota and GNOME OS build patterns.

The [multi-runner pipeline](https://github.com/tuna-os/tromso/actions/workflows/build-tromso-multirunner.yml)
splits the BuildStream graph into chunks and merges their content-addressed
artifacts before final image composition. Publication is configured to use
cosign keyless signing with GitHub Actions OIDC; the
[README](https://github.com/tuna-os/tromso#verifying-signatures) documents the
expected signer identity and verification commands. These describe the build
and verification design, rather than a guarantee that every run publishes an
image.

Tromso remains Alpha according to its
[roadmap](https://github.com/tuna-os/tromso/blob/main/ROADMAP.md). Build,
installation, release operations, user guidance, and desktop validation are
release gates. Please consult the roadmap and linked workflow runs for current
evidence before treating an artifact as suitable for testing. This introduction
is an invitation to collaborate, rather than a stable release announcement.

We welcome feedback from Plasma packagers and image-based desktop developers:
which desktop smoke tests would be most useful, and where can our BuildStream
packaging work help other community efforts? Please report Tromso-specific
problems in [our issue tracker](https://github.com/tuna-os/tromso/issues).

- [Project overview and build instructions](https://github.com/tuna-os/tromso#readme)
- [Pipeline and ISO documentation](https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md)
- [Contribution guide](https://github.com/tuna-os/tromso/blob/main/CONTRIBUTING.md)

Thank you for building the desktop on which this work depends.

## Short forum / Invent cross-post

Title: Tromso: exploring KDE Plasma 6 with BuildStream and bootc

Tromso is a TunaOS community project building a KDE Plasma 6 desktop on
freedesktop-sdk with BuildStream, targeting OCI/bootc system images. Its
repository includes multi-runner build orchestration, keyless signing
configuration, and live ISO tooling. It is independent of the official KDE
Linux project and remains Alpha; please read the roadmap and current build
evidence before testing.

We would appreciate feedback on Plasma smoke tests and opportunities to share
BuildStream packaging work. Overview, build instructions, and contribution
links: https://github.com/tuna-os/tromso#readme

Release gates: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md

Tromso-specific reports: https://github.com/tuna-os/tromso/issues

When cross-posting, add the canonical announcement URL so discussion can be
followed across channels.

## Evidence and publication checklist

A maintainer should review the final copy and act as the public contact before
sending it. Record the sender and publication URLs in issue #365. Publication
is still outstanding after this kit is merged.

- Reconcile the README's functional-desktop claim with the roadmap's Alpha
  gates. Do not repeat the issue's claims of maturity or verified boot without
  a successful run URL, candidate commit/digest, and tested configuration.
- Check the [build workflow](../../.github/workflows/build-tromso-multirunner.yml),
  [ISO workflow](../../.github/workflows/build-iso.yml), and
  [pipeline guide](../ci-and-iso-pipeline.md) against the final copy. If adding
  artifact links, verify availability and signatures for that exact artifact.
- Keep the wording at Plasma 6 unless the shipped package versions and a
  desktop smoke test justify a more specific version. Avoid date-based claims
  about upstream releases or enterprise adoption.
- For KDE News/editorial coverage, ask the
  [KDE press contact](https://kde.org/contact/) for the current appropriate
  submission route. Do not assume the old KDE.News site accepts submissions.
- For community discussion, use [KDE Discuss](https://discuss.kde.org/), whose
  Community and Announcement categories describe their scope. Choose the
  appropriate category under its current rules.
- Confirm the KDE-Linux SIG's preferred channel with its participants before
  posting. The [KDE mailing-list directory](https://mail.kde.org/mailman/listinfo/)
  and [kde-community scope](https://mail.kde.org/mailman/listinfo/kde-community)
  are starting points; do not assume a SIG address or use an unrelated list.
- Cross-post to KDE Invent only where a relevant project explicitly welcomes
  community announcements. Confirm the venue first; do not create unrelated
  code issues as advertising. Use the short copy and canonical announcement URL.
- Add `https://docs.tunaos.org` only after the Tromso variant matrix page is
  live and reviewed; link its exact page. Until then use the repository docs
  above, without a placeholder documentation link in the outgoing copy.
- Record each live URL and any moderation/pending status in #365; keep the
  issue open until publication and the intended cross-posts are accounted for.
