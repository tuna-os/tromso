# proto-installer — provenance

**Status: unpinned vendored snapshot. See tuna-os/tromso#196.**

This directory (`installer.py`, `daemon/` Rust daemon, the `org.gnome.Installer*`
D-Bus/systemd/polkit units, and the accompanying UI/resource files) is a
vendored snapshot of a GNOME OS installer prototype, wired into the KDE live
image build via `../meson.build` (`subdir('proto-installer')`) and the Rust
daemon's `cargo2` sources in `elements/kde-linux-system/live.bst`.

## What is actually known about its origin

- It entered *this* repo's history in commit `15cf8a5` ("Consolidate
  kde-build-meta directly into tromso, remove the junction", 2026-07-20) as
  part of a `git subtree add --squash` import of the (now-retired)
  `tuna-os/kde-build-meta` repo. That import intentionally discarded
  `kde-build-meta`'s own commit history, so this repo's `git log` cannot
  trace the file further back than that single squash commit.
- Nothing in `kde-build-meta`'s copy — no README, no `.gitmodules`, no
  comment in `installer.py`/`main.rs`/`meson.build` — recorded which upstream
  project or commit these files were vendored from, or when.
- The naming (`org.gnome.Installer` D-Bus service, `gnomeos-installer`
  install prefix, GTK4 + Adwaita UI, a Rust daemon driving UDisks/logind/
  polkit/systemd over D-Bus) is consistent with a GNOME OS team installer
  prototype, but this document does not assert a specific upstream repo URL
  or commit hash — doing so without being able to verify it against a real
  source would just be a second, more convincing-looking version of the same
  problem this file exists to fix. Confirming the actual upstream project
  and pinning to it is unfinished work, not something resolved by this
  commit.

## Why this file exists

tuna-os/tromso#196 flagged that this tree has **no provenance record at
all**: no pin, no submodule, no sync mechanism, so there is no way to answer
"what did we change from upstream, and when does upstream supersede us?" —
the same failure mode already seen with `tuna_installer/` in
tuna-os/fisherman#104, and relevant to the org's broader installer-backend
duplication tracked in tuna-os/tunaos#1197.

This README does not resolve that gap — it records what's known and marks
what still needs a maintainer decision, per #196's own recommendation:

1. **Identify and pin the real upstream** (submodule or a recorded commit
   reference), if one can be confirmed — needed before this tree can safely
   receive upstream fixes (security, partitioning, TPM/verity handling)
   instead of drifting silently.
2. **Decide intent**: adopt this installer officially (in which case it
   should be re-branded — `org.gnome.Installer` → something like
   `org.tunaos.Installer` — so a KDE live image doesn't ship a
   GNOME-branded D-Bus service), or delete it and standardize on the
   bootc-installer family per tuna-os/tunaos#1197.

Both of those are maintainer-level architectural calls (rename touches
`org.gnome.Installer.desktop.in`, `org.gnome.Installer.service`,
`org.gnome.Installer1.{conf,policy,rules,service}`, and `gnomeos-installer*`
paths across `meson.build` and the systemd unit — a mechanical but
wide-blast-radius change that shouldn't be made ahead of the "does this
stay" decision), so this commit is documentation only.
