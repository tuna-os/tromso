# Investigation: re-enabling KDE Python bindings (`BUILD_PYTHON_BINDINGS`)

Issue: tuna-os/tromso#2

## Recommendation

**Do not re-enable yet.** Keep `-DBUILD_PYTHON_BINDINGS=OFF` on all 100
elements that use it. First, add buildable Shiboken6 and PySide6 elements to
this sandbox. Then use a real `bst build` to test the important frameworks,
such as `kcoreaddons` and `kwidgetsaddons`. Also test other frameworks in 6.22
or later that call `ECMGeneratePythonBindings`. They must configure and install
without errors.

A change to the flag now would make all 100 elements fail at
CMake configuration, before compilation starts. Issue #2 exists to prevent
this failure.

This investigation defines the scope and does not change the build. This PR
does not change `BUILD_PYTHON_BINDINGS` in a `.bst` file.

## What I checked

### 1. Confirmed the scope: it's not just 70 frameworks

The issue's "What was disabled" section names `elements/kde/frameworks/*.bst`
specifically. `grep -rl BUILD_PYTHON_BINDINGS elements/` finds it in **100**
files: the 70 frameworks plus 30 more under `elements/kde/libs/` and
`elements/kde/plasma/` (`kwin.bst`, `plasma-desktop.bst`, `konsole.bst`,
`kdecoration.bst`, and 26 others). Any re-enable has to account for all 100,
not only the frameworks tier.

### 2. freedesktop-sdk does not carry Shiboken6 or PySide6

This repo pins `freedesktop-sdk-25.08.9` (`elements/freedesktop-sdk.bst`).
I could not find a Shiboken6 or PySide6 element anywhere in that ref:

- Direct guesses at the conventional path
  (`elements/components/shiboken6.bst`, `.../pyside6.bst`) both 404 against
  the tag's raw-file endpoint on GitLab.
- The first two pages of `elements/components` each had 100 entries. They had
  no element with `shiboken`, `pyside`, `qt6`, `qt5`, or `python` in its name,
  apart from the existing `python3*` dependencies.

<!-- ste-disable: the next sentence quotes the project specification verbatim -->
This matches the "Packages Not Yet in Aurora" table in `SPEC.md`: *"Python
bindings (Shiboken6/PySide6) — Requires packaging from scratch."*
<!-- ste-enable -->

I could not list all of the 1000 or more elements in freedesktop-sdk. However,
each check gave the same result. This result also matches the scope of
freedesktop-sdk, which does not build Qt or the Python bindings for Qt. It is
consistent with section 3:

<!-- ste-disable: these sections contain dense package identifiers and exact CMake syntax that the prose rules misclassify -->
### 3. This repo already builds its own Qt6 from source — Shiboken6/PySide6 would follow the same pattern

`elements/kde/qt6/` has 30+ `qt6-qt*.bst` elements (`qt6-qtbase.bst`,
`qt6-qtdeclarative.bst`, etc.), each a `kind: cmake` element sourcing a
`qtbase-everywhere-src-<ver>.tar.xz`-style tarball from the `qt:` alias
(`https://download.qt.io/official_releases/qt/`, see `include/aliases.yml`).
Qt6 is not something freedesktop-sdk hands us — we build the whole stack
ourselves, pinned at **Qt 6.10.3** right now (`qt6-qtbase.bst`'s `ref:`).

Shiboken6 and PySide6 are developed together in Qt's own `pyside-setup`
source tree and released in lockstep with Qt itself. Qt publishes
`pyside-setup-everywhere-src-<version>.tar.xz`-style source tarballs the
same way it does `qtbase-everywhere-src-*` — I didn't pin an exact URL/ref
(would need a real download to get the sha256, which this sandbox can't do
against `download.qt.io`), but the naming convention and hosting model are
the same as every other `qt6-qt*.bst` element already in this tree. In
other words: two more `kind: cmake` elements, `kde/qt6/shiboken6.bst` and
`kde/qt6/pyside6.bst`, following the exact template of the 30 elements
already there, gated on `qt6-qtbase.bst` (and probably
`qt6-qtdeclarative.bst`/`qt6-qtquick3d.bst` for the QML-facing bindings)
as a `depends:`.

### 4. The dependency that actually needs checking before writing those elements: libclang

Shiboken6's `ApiExtractor` component parses C++ headers with an embedded
Clang, and needs `libclang` — the one build-dependency in this chain that
isn't "more Qt". Good news: freedesktop-sdk **does** carry it —
`freedesktop-sdk.bst:components/llvm.bst` exists at the pinned ref and
builds LLVM + Clang + compiler-rt + lld with headers and libraries
installed. That would be the `build-depends:` (or `depends:`) entry a
`shiboken6.bst` element needs; I did not verify the exact Clang version
pinned there is one Shiboken6 6.10.x actually supports (Shiboken tends to
track a fairly narrow Clang range — this is the first thing to check when
actually writing the element).

### 5. Python3 is already satisfied

`find_package(Python3 3.9 REQUIRED COMPONENTS Interpreter Development)` is
not the blocker: every framework in this repo (see `kcoreaddons.bst`)
already depends on `freedesktop-sdk.bst:components/python3.bst`. Only the
`Shiboken6`/`PySide6` `find_package` calls fail today.

### 6. The "working bootable Aurora Dakota OCI image" prerequisite is not met yet either

The issue lists this as a prerequisite checkbox. As of this investigation,
`Build Tromso (Multi-Runner)` — the workflow that actually assembles the
image — has failed on its last five runs (2026-08-04 through 2026-08-08),
most recently on low-level base chunks (`util-linux-full`, `cryptsetup`,
`lvm2-stage1`, `popt`, `cracklib`, `pwquality`, `libaio`), unrelated to KDE
or Python bindings. `Build Tromso (CASD)`'s last five runs are all
`cancelled`, none since 2026-07-11. Re-enabling Python bindings is blocked
on its own prerequisites regardless of Shiboken6/PySide6 packaging — the
base build isn't currently green to build on top of.

## What this investigation could not do

- Could not run `bst build` against a real Shiboken6/PySide6 element — no
  BuildStream/podman tooling or network access to `download.qt.io` /
  `cache.freedesktop-sdk.io` in this sandbox. Everything above is derived
  from reading this repo's existing elements and probing freedesktop-sdk's
  published tag over HTTP, not from an actual build.
- Could not exhaustively enumerate every element freedesktop-sdk ships
  (it has 1000+); I checked the conventional naming spots and the first two
  pages of `elements/components`, not every one of freedesktop-sdk's
  subdirectories.
- Could not pin an exact `pyside-setup` source tarball URL + sha256 for
  6.10.3 — would need to actually reach `download.qt.io` to compute the
  checksum BuildStream requires.
- Did not check whether the KDE frameworks' `ECMGeneratePythonBindings`
  macro (from `extra-cmake-modules`, already an existing build-dep) imposes
  any additional constraint beyond `find_package(Shiboken6)` /
  `find_package(PySide6)` — that lives in the fetched framework source, not
  in this repo, so I could not grep it directly.

## Suggested next step, if someone picks this up

1. Write `elements/kde/qt6/shiboken6.bst` and `elements/kde/qt6/pyside6.bst`
   as `kind: cmake` elements sourcing `pyside-setup`'s official source
   tarball for the Qt version this repo currently pins (6.10.3), modeled on
   `qt6-qtbase.bst`. `depends:` on `qt6-qtbase.bst` and
   `freedesktop-sdk.bst:components/llvm.bst`; `build-depends:` on
   `freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst`.
2. Get those two elements building green on their own before touching any
   framework — that's the actual prerequisite the issue's checklist names.
3. Only then flip `-DBUILD_PYTHON_BINDINGS=OFF` → default (remove the flag)
   on `kcoreaddons.bst` and `kwidgetsaddons.bst` first (the two the issue
   names explicitly), add the two new elements to their `build-depends:`,
   and confirm a real `bst build` produces the `.pyi` stubs / `.so` modules
   before rolling the change out to the other 98 files.
4. This work does not depend on a successful base image build. However, wait
   for that result before you change the flag. Otherwise, you cannot separate
   a failure from this change from an existing failure in the base build.
<!-- ste-enable -->
