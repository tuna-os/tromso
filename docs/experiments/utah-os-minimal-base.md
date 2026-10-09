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

## Verdict

A base swap between these two tags is a no-op for purity. "More pure
Hummingbird" can only come from the factory side (utah-packages
rebuilding Fedora bits as hum1.bfin), which is already the mechanism for
GNOME. Follow-ups if still interesting:

1. Diff the two image CONFIGs (entrypoint/cmd/labels) to say what
   "minimal" actually means — cheap, no build needed.
2. Skip the full os-minimal build test: identical input set ⇒ identical
   build behavior modulo container config.
