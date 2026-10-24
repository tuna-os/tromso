# Branding audit for issue #373

Source audit: 2026-10-24, upstream `main` at `33c6bea`.
This inventories repository inputs; it does not certify published images,
the website, third-party asset permissions, or community agreement.

## Existing removal

[PR #301](https://github.com/tuna-os/tromso/pull/301) merged as
`6d470c64fade4324c8c5b0ea59225e601c516a92` on `main`. It removed the
Aurora logo directory, character artwork, look-and-feel packages, and the
logo, wallpaper and Aurora guide elements. README records attribution and
non-affiliation. The selected look-and-feel is stock Breeze Dark; fastfetch
selects the builtin `kdelinux` logo. This is not a new Tromso logo.

`elements/tromso/image-overlay.bst` fetches Aurora configuration and deletes
PNG, JPG, JPEG, JXL, SVG, SVGZ, WebP and GIF files before staging. That guard
covers this overlay, not every image input or downloadable package.

## Remaining source findings

Paths below are relative to
`files/tromso/aurora-common/system_files/shared/usr/share/`.
`elements/tromso/common.bst` copies this vendored `usr` tree into the image.

| Surface | File | Finding |
| --- | --- | --- |
| About distribution | `kde-settings/kde-profile/default/xdg/kcm-about-distrorc` | Names Aurora, links getaurora.dev and requests `/usr/share/pixmaps/system-logo.png`. The path alone does not establish which logo is present at runtime. |
| Lock screen | `kde-settings/kde-profile/default/xdg/kscreenlockerrc` | Image and preview point to `/usr/share/wallpapers/Aurora/`, whose provider was removed. |
| Splash | `kde-settings/kde-profile/default/xdg/ksplashrc` | Selects deleted `dev.getaurora.aurora.desktop`. |
| Welcome | `plasma/plasma-welcome/intro-customization.desktop` | Welcomes users to Aurora, requests `distributor-logo`, and links Aurora's blog. |
| Favorites | `kde-settings/kde-profile/default/xdg/kicker-extra-favoritesrc` | Refers to removed `dev.getaurora.aurora-docs.desktop`. |
| Optional artwork | `ublue-os/homebrew/artwork.Brewfile` | Lists `aurora-wallpapers`. A package entry is not evidence that the wallpapers are installed in a published image. |
| Terminal messaging | `ublue-os/motd/template.md` | Welcomes users to Aurora and directs support links to Aurora. |

The only image-extension file found under `files/tromso` is
`aurora-common/system_files/shared/usr/share/icons/hicolor/scalable/apps/framework.svg`.
Its filename does not establish authorship or permission. Source URLs,
licenses and provenance comments must remain attributable when configuration
is adapted.

## Follow-up and acceptance evidence

- Correct stale desktop configuration and messaging in a focused follow-up;
  verify the About page, welcome, splash, lock screen and favorites in a
  booted image. Check the optional artwork installation path separately.
- Inspect the actual published OCI image and live ISO for logo assets and
  stale references. Record image digests and screenshots; this source audit
  cannot establish what an older published artifact contains.
- Audit website assets in their owning repository or publishing service.
  This checkout provides no evidence that the published website is clear.
- A maintainer should respond to the designer in
  [#305](https://github.com/tuna-os/tromso/issues/305), referencing #301 and
  explaining any remaining remediation. Do not claim designer approval or
  promise a deadline without an agreed owner.
- Maintainers should choose the replacement identity and approve the design
  collaboration brief before outreach to KDE VDG or community designers.
  Record contributor names, consent to credit, asset provenance and usage
  terms before publishing accepted artwork. No outreach or permission grant
  is recorded by this audit.

[#373](https://github.com/tuna-os/tromso/issues/373) remains open for those
implementation, publication and community outcomes; #301 alone does not
establish all of its success metrics.
