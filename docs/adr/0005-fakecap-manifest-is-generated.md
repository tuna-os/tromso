# ADR 0005: The fakecap manifest is build output, not an input

- Status: accepted
- Date: 2026-09-19
- Issue: [tuna-os/tromso#277](https://github.com/tuna-os/tromso/issues/277)
- Org tracker: [tuna-os/tunaOS#2290](https://github.com/tuna-os/tunaOS/issues/2290)

## Context

Commit `df96a3d` added `files/fakecap-manifest.tsv` in May 2026. The file is
70,309,086 bytes across 704,805 lines. Commit `0ddf4ee` removed it five days
later. The removal reclaims no space, because the blob stays in history.
`.git` is 20 MB today, and most of that is this one blob.

Issue #277 asks the correct question first. Is this manifest an input or an
output?

It is an output, and it belongs to a different project. Each line maps a path
to the element that owns it. The element names in that file are
`bluefin/*`, `gnomeos*`, `components/*` and `bootstrap/*`. The file has 20,594
lines for `bluefin/*` alone. It has zero lines for `kde/*` or `tromso/*`.

The commit message for `df96a3d` states the origin: "Add Dakota fakecap
assets for chunkify". Someone copied the manifest from a Dakota build. The
message for `0ddf4ee` reaches the same conclusion: "a generated artifact
produced at runtime".

So the manifest was never a valid input here. `just chunkify` gives each path
a `user.component` xattr from that map. A Dakota map on a Tromso rootfs
labels the wrong elements, or no element at all.

The repository also lost the other half of the tooling.
`files/fakecap/fakecap-restore.c` arrived in the same commit. The merge
`74465bc` brought in the ISO builder, and it dropped that file. No commit
records the loss. The person who resolved the merge took the other side.

`just chunkify` therefore checks for both inputs and exits early. Neither
file exists, so the check always exits. `just export` calls `just chunkify`,
and CI calls `just export`. No published image gets chunks today.

## Decision

The manifest is a build output. It does not belong in git. A future
`just chunkify` must generate the map from Tromso's own element graph.

`.gitignore` keeps a rule for the exact path. A rule alone is weak: the
blanket `files/` rule was already there in May 2026, and the 67 MB commit
went in anyway. `tests/pytest/test_repo_hygiene.py` is the real gate. It
fails on any tracked file over 5 MB, which is the same bar as the org-wide
scan.

This ADR also removes the blanket `files/` and `patches/` rules from
`.gitignore`. Both trees hold real build inputs, with 367 and 81 tracked
files. Those rules made `git add` refuse a new input and hid it from
`git status`. That is how the loss of `fakecap-restore.c` stayed invisible.

## What this does not do

It does not rewrite history. A rewrite needs `git filter-repo` and a
force-push. Every commit SHA changes, every open PR breaks, and every clone
breaks. tunaOS#2290 puts that step in an org-wide sequence, and one
repository must not do it alone.

It does not revive `just chunkify`. That needs a generator for the map, which
is new work and a separate issue.

It does not touch `xfce-linux`. That repository has the same file at 53.4 MB,
also history-only, in tuna-os/xfce-linux#138. The conclusion here applies
there, because the manifest has the same origin. Someone must confirm that.

## Gates for the history rewrite

1. This repository stops the recurrence. That is what this change does.
2. `xfce-linux` reaches the same decision for its own copy.
3. tunaOS#2290 names a date, and the maintainers warn every person with a
   clone or an open PR.
