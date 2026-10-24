# proto-installer — pinned upstream snapshot

This is the GNOME OS installer prototype from
[GNOME/gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta),
not a separate installer repository. The source pin is recorded in
[`upstream.json`](upstream.json):

- Commit: [`f26d7fc2e0dfed32e5f7329cb2052d766f08b719`](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/commit/f26d7fc2e0dfed32e5f7329cb2052d766f08b719)
  (`live: Fix meson deprecation warnings`, authored 2026-04-01).
- Subdirectory: `files/gnomeos/live/proto-installer`.
- Upstream tracking branch: `master`.
- All **29 source files**, including icons and translations, match that
  revision byte for byte and in Git executable mode. There are no local
  source patches. Only this README and `upstream.json` are local metadata.

This establishes an exact matching source revision, not proof of which
commit the original importer checked out: multiple upstream repository
commits can contain the same installer subtree. Comparison of successive
installer-changing commits found this exact match; the next such commit,
`28227c820a2fd8db907f55b3876439b4403116a9`, changes the installer files.

The snapshot entered Tromso in `15cf8a5` via the squashed
`tuna-os/kde-build-meta` import. The build still uses `../meson.build`
(`subdir('proto-installer')`) and the Rust daemon's `cargo2` sources in
`elements/kde-linux-system/live.bst`. Keeping the files vendored preserves
those build inputs without requiring recursive submodule checkout.

## Verify and monitor

From the repository root, using a GNOME source checkout:

```sh
git clone https://gitlab.gnome.org/GNOME/gnome-build-meta.git /tmp/gnome-build-meta
python3 scripts/check-proto-installer.py /tmp/gnome-build-meta
python3 scripts/check-proto-installer.py /tmp/gnome-build-meta --tip origin/master
```

The first command checks every vendored source path, content hash, and mode
against the pin, including additions and deletions. The second also reports
upstream changes with a full diff and exits nonzero if review is needed.
The **Proto-installer upstream drift** workflow runs that comparison weekly
and on manual dispatch. It is expected to fail while upstream changes await
review; inspect its job log for the diff. Pull requests touching the snapshot
or checker verify only the local pin, so newer upstream work does not prevent
unrelated local maintenance.

To sync, review the upstream diff (particularly disk partitioning,
TPM/verity, and D-Bus behavior), copy the complete upstream subtree while
preserving these two metadata files, and update `upstream.json` in the same
PR. Re-run the checker, refresh the daemon's Cargo source entries in
`elements/kde-linux-system/live.bst` if needed, and validate the live image
through the repository's `just` recipes. The workflow never modifies source
or advances the pin automatically.

This resolves the provenance and drift-monitoring work in #284. Whether to
adopt/rebrand this GNOME installer or retire it in favor of the bootc
installer remains the separate architectural question in #196 and
tuna-os/tunaos#1197.
