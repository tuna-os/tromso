# Aurora Dakota — Agent Context

Aurora is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's `projectbluefin/dakota`.
It builds KDE Plasma 6 on top of freedesktop-sdk using two repos:

- **`hanthor/tromso`** — top-level OCI project (this repo)
- **`hanthor/kde-build-meta`** — KDE `.bst` elements (junctioned in)

---

## Two-Repo Model

All KDE package definitions live in `hanthor/kde-build-meta`.
After committing there, update the junction in this repo (`elements/kde-build-meta.bst`):

```bash
# 1. Commit + push kde-build-meta
cd /var/home/james/dev/kde-build-meta
TMPDIR=/var/tmp git commit -m "..."
git push origin master

# 2. Get new tarball SHA256 (must re-download after push — GitHub tarballs are non-deterministic)
SHA=$(git rev-parse --short=7 HEAD)
curl -sL https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz | tee /tmp/kbm.tar.gz | sha256sum
tar tzf /tmp/kbm.tar.gz | head -1   # get base-dir

# 3. Update elements/kde-build-meta.bst with new url, ref, base-dir

# 4. Commit tromso
cd /var/home/james/dev/kde-linux
TMPDIR=/var/tmp git commit -m "Update junction to kde-build-meta ${SHA} (...)"
```

**CRITICAL**: Always use `TMPDIR=/var/tmp` for git commits — `/tmp` is full.
**CRITICAL**: Always use short SHA (7 chars) in GitHub archive URLs for stability.
**CRITICAL**: GitHub archive SHA256 changes each request — compute it fresh after every push.
**CRITICAL**: `base-dir` must match the exact directory name extracted from the tarball (full SHA in name).

---

## Build Command

```bash
nohup podman run --name aurora-build --privileged --device /dev/fuse --network=host \
  -v "/var/home/james/dev/kde-linux:/src:rw" \
  -v "/var/home/james/.cache/buildstream:/root/.cache/buildstream:rw" \
  -w /src \
  "registry.gitlab.com/freedesktop-sdk/infrastructure/freedesktop-sdk-docker-images/bst2:f89b4aef847ef040b345acceda15a850219eb8f1" \
  bst --colors --max-jobs 16 --fetchers 32 build oci/aurora.bst \
  >> /var/tmp/aurora-build.log 2>&1 &
disown
```

- `--max-jobs 16` — builders (do not raise above 16; 32 locked up the desktop)
- `--fetchers 32` — fetchers (more is fine; improves network utilisation)
- Never use `just bst-build` directly in an agent — it blocks with `tail -f`
- Log: `/var/tmp/aurora-build.log`
- Container restart: `podman stop aurora-build && podman rm aurora-build` then re-run

---

## Fixing a Failed Element

1. Check the build log for the element name:
   ```bash
   grep "FAILURE" /var/tmp/aurora-build.log | grep -v "^    "
   ```

2. Read the detailed log:
   ```bash
   ls -t ~/.cache/buildstream/logs/gnome/kde-frameworks-ELEMENT/ | head -1 | \
     xargs -I{} cat ~/.cache/buildstream/logs/gnome/kde-frameworks-ELEMENT/{}
   ```

3. Fix the `.bst` file in `hanthor/kde-build-meta`.

4. **Clear the cached failure** (BST caches failed artifacts):
   ```bash
   rm -rf ~/.cache/buildstream/artifacts/refs/gnome/kde-*
   rm -rf ~/.cache/buildstream/logs/gnome/kde-*
   ```

5. Commit + push `kde-build-meta`, update junction, restart build.

---

## Common Build Patterns

### All KDE cmake elements need:

```yaml
build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst   # needed at configure time for Qt6 CMake detection
```

Use `cmake-local` (NOT `cmake-options`) for cmake flags:

```yaml
variables:
  cmake-local: -DBUILD_TESTING=OFF
```

### KDE frameworks that depend on other KDE frameworks

CMake config detection requires the dependency to be present in the **sandbox** at configure time.
Any KDE framework listed in `depends:` that is needed by CMake `find_package()` **must also appear in `build-depends:`**.

Pattern — if upstream `CMakeLists.txt` has `find_package(KF6Foo REQUIRED)`, then `kde/frameworks/foo.bst` must be in `build-depends`.

### Modules already in freedesktop-sdk (do NOT redefine)

| Package | freedesktop-sdk element |
|---|---|
| pam | `freedesktop-sdk.bst:components/linux-pam-base.bst` |
| polkit | `freedesktop-sdk.bst:components/polkit.bst` |
| NetworkManager | `freedesktop-sdk.bst:components/networkmanager.bst` |

---

## Repository Structure

```
hanthor/tromso          (this repo)
├── elements/
│   ├── kde-build-meta.bst     junction → hanthor/kde-build-meta
│   └── oci/aurora.bst         top-level build target
└── Justfile

hanthor/kde-build-meta
└── elements/kde/
    ├── qt6/       (29 elements — qt6-qtbase, qt6-qtdeclarative, etc.)
    ├── frameworks/ (69 elements — kcoreaddons, kio, kirigami, etc.)
    ├── libs/      (7 elements)
    ├── plasma/    (40 elements — plasma-workspace, kwin, sddm, etc.)
    └── apps/      (7 elements — dolphin, konsole, kate, etc.)
```

---

## Known Issues / History

- **Qt6Gui/Qt6Widgets not found in sandbox**: Fixed by adding `kde/qt6/qt6-qtbase.bst` to `build-depends` of all KDE cmake elements. The freedesktop-sdk sandbox does not expose Qt unless explicitly requested.
- **kio build-depends**: kio needs all its KDE framework dependencies also listed in `build-depends` (kconfig, kcoreaddons, ki18n, kservice, solid, kcrash, kwindowsystem, kbookmarks, kcolorscheme, kcompletion, kguiaddons, kiconthemes, kitemviews, kjobwidgets, kwidgetsaddons, kdbusaddons, kauth, kcodecs).
- **GitHub tarball non-determinism**: SHA256 changes on each request. Always download fresh and recompute. The `base-dir` uses the full 40-char SHA in the directory name.
- **aliases.yml triggers full rebuild**: `include/aliases.yml` is part of the project configuration hash. Adding a new alias invalidates the cache key for **every element** in the project, forcing a complete rebuild. Only add aliases to `aliases.yml` when multiple elements will use them. For a single new element, use a direct `https://` URL instead.
