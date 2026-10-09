# Experiment: utah base bootc-os vs os-minimal

Branch: `exp/utah-os-minimal-base`. Workflow: `utah-base-diff.yml`.
Run 37983322557 (green), utah@b6825a3866cd, 2026-10-09.

Question: is `quay.io/hummingbird-community/os-minimal` a purer
(more Hummingbird, less Fedora) base for utah than `bootc-os`?

## Pins compared

- bootc-os: `quay.io/hummingbird-community/bootc-os:latest@sha256:c1b785e5a38b1834580b62b175f`
  (utah's current pin, read live from its Containerfile)
- os-minimal: `quay.io/hummingbird-community/os-minimal:latest@sha256:b696a563751a0f945688171327c42142841c319533e001408eda9bba73cd4950`

## Result: identical RPM sets

| side | RPMs | hummingbird | fedora | other |
|---|---|---|---|---|
| bootc-os | 262 | 249 | 11 | 2 |
| os-minimal | 262 | 249 | 11 | 2 |

Only-in-either: 0. Drifted versions: 0. Same EVRs across all 262 names.

os-minimal:latest is the same rootfs as bootc-os today (different
manifest digest = container config/labels at most). Switching the base
ARG changes nothing about Fedora poisoning: both bases are already ~95%
Hummingbird rebuilds. The 11 Fedora RPMs are identical in both.

## Gap analysis (what a switch would require adding to manifests)

- `gap_needs_manifest_add`: **empty** — nothing utah needs is in
  bootc-os but missing from os-minimal.
- `boot_critical_missing_from_minimal`: **gdm only** — and gdm is in
  NEITHER base nor either manifest (0 hits in both tomls). It must arrive
  as a dependency (or via the factory transaction) on both bases equally,
  so it is not a switch blocker, but worth confirming in a real build.
- `needed_from_repos_either_way`: 203 names — the actual Fedora surface.
  These resolve from Hummingbird's repo (Fedora builds) and the factory;
  no base swap touches them.

## Definitive difference (config + layer diff, run 37987401651)

- Layers: 32 each, **26 shared digests**. The 6 unique layers pair up at
  near-identical sizes (3,776,363 vs 3,776,362 bytes; 9,671,088 vs
  9,671,090; …; totals 440,338,705 vs 440,338,506 — 199 bytes apart on
  440 MB). Same content, different compression/metadata.
- Image config: identical except `created` and Labels. bootc-os says
  `"An experimental minimal bootable container image"`,
  containerfile `images/bootc-os/hummingbird/default/Containerfile`;
  os-minimal says `"A minimal bootable container image"`, containerfile
  `generated/images/os-minimal/hummingbird/default/Containerfile`.

So os-minimal is a rebuild/repack of the same rootfs under the
productized recipe (note `generated/` and the dropped "experimental"):
same 262 RPMs, same versions, same bytes on disk, new layer compression.

## Verdict

A base swap between these two tags is a no-op, functionally and for
purity. "More pure Hummingbird" can only come from the factory side
(utah-packages rebuilding Fedora bits as hum1.bfin), which is already
the mechanism for GNOME. No build test needed: identical input set ⇒
identical build. If Hummingbird ever lets the two recipes diverge, the
`gap_needs_manifest_add` field in base-diff.json is the exact ADD list —
today it is empty.
