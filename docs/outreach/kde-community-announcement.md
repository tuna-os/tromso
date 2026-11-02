# KDE community announcement kit

Issue: [#365](https://github.com/tuna-os/tromso/issues/365).

Status: drafts for maintainer review. Maintainers have not posted an external announcement.

## Announcement and editorial pitch

Subject: TunaOS Tromsø: a community project for Plasma 6 with BuildStream and bootc

Hello KDE community,

We would like to introduce [TunaOS Tromsø](https://github.com/tuna-os/tromso), an independent Alpha project.
We compose a Plasma 6 desktop with BuildStream on `freedesktop-sdk`. The goal is OCI images for `bootc`.
Tromsø has no KDE endorsement and is not a variant of KDE Linux.

The repository contains KDE recipes, OCI composition, and live ISO tools.
The approach draws on Project Bluefin Dakota and GNOME OS build patterns.
We explore source composition and OS updates based on images.

The [pipeline](https://github.com/tuna-os/tromso/actions/workflows/build-tromso-multirunner.yml) divides the BuildStream graph into chunks.
It merges content-addressed artifacts before final composition.
Publication uses Cosign with OIDC from GitHub Actions.
The [README](https://github.com/tuna-os/tromso#verifying-signatures) specifies the expected signer identity and verification commands.
This design does not guarantee that each run publishes an image.
It also does not establish bit-for-bit reproducibility.

Tromsø remains Alpha under its [roadmap](https://github.com/tuna-os/tromso/blob/main/ROADMAP.md).
Release gates cover builds, installation, release operations, user guidance, and desktop tests.
Consult the roadmap and linked runs before a candidate test.
This is an invitation to collaborate, not a stable release announcement.
We do not claim qualified installation, update, or rollback paths.

We welcome feedback from Plasma packagers and developers of desktops based on images.
Which desktop smoke tests would help most? Where could our BuildStream recipes help other community projects?
Report Tromsø-specific problems in [our issue tracker](https://github.com/tuna-os/tromso/issues).

- [Project overview and build instructions](https://github.com/tuna-os/tromso#readme)
- [Pipeline and ISO documentation](https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md)
- [Contribution guide](https://github.com/tuna-os/tromso/blob/main/CONTRIBUTING.md)

Thank you for your work on Plasma and its dependencies.

## Short forum or Invent draft

Title: TunaOS Tromsø: Plasma 6 with BuildStream and bootc

TunaOS Tromsø is an independent Alpha project that composes Plasma 6 with BuildStream on `freedesktop-sdk`.
It targets OCI images for `bootc`. The repository includes CI across multiple runners, Cosign configuration, and live ISO tools.
Tromsø has no KDE endorsement and is separate from KDE Linux.
Read the roadmap and exact build evidence before a candidate test.

We welcome feedback on Plasma smoke tests and ways to share BuildStream recipes.

- Overview, build instructions, and contribution links: https://github.com/tuna-os/tromso#readme
- Release gates: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md
- Tromsø-specific reports: https://github.com/tuna-os/tromso/issues

For a cross-post, add the canonical announcement URL so readers can find discussions across channels.

## Evidence and publication checklist

A maintainer must approve final copy and act as the public contact before publication.
Record the sender and publication URLs in issue #365.
A merge of this kit does not publish outreach.

- Check the README and roadmap for conflicts in maturity claims. Resolve them before publication.
- Do not claim verified boot without a successful run URL, candidate commit or digest, and tested configuration.
- Compare the copy with the [build workflow](../../.github/workflows/build-tromso-multirunner.yml).
- Also check the [ISO workflow](../../.github/workflows/build-iso.yml) and [pipeline guide](../ci-and-iso-pipeline.md).
- Verify availability and signatures for each exact artifact before a link to it.
- Use Plasma 6 as the version label. A more specific claim needs package evidence and a desktop smoke test.
- Avoid claims about upstream release dates or enterprise adoption.
- Ask the [KDE press contact](https://kde.org/contact/) for the appropriate route for editorial submissions.
- Do not assume the old KDE.News site accepts submissions.
- Check the scope of Community and Announcement categories on [KDE Discuss](https://discuss.kde.org/).
- Choose a category under its current rules.
- Ask participants in the KDE-Linux SIG for their preferred channel before contact.
- Consult the [KDE list directory](https://mail.kde.org/mailman/listinfo/) and [kde-community scope](https://mail.kde.org/mailman/listinfo/kde-community).
- Do not assume a SIG address or use an unrelated list.
- Cross-post to KDE Invent only with permission from the relevant project.
- Confirm the venue first. Do not create unrelated code issues for publicity.
- Use the short draft and canonical announcement URL for approved cross-posts.
- Add `https://docs.tunaos.org` only after review of a live page for Tromsø in the variant matrix.
- Link that exact page. Until then, use the repository docs without a placeholder link.
- Record each live URL and moderation status in #365.
- Keep #365 open until maintainers account for publication and the intended cross-posts.
