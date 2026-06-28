# Aurora KDE Linux — Agent Context

Aurora is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's `projectbluefin/dakota`.
It builds KDE Plasma 6 on top of freedesktop-sdk using two repos:

- **`tuna-os/tromso`** — top-level OCI project (this repo)
- **`hanthor/kde-build-meta`** — KDE `.bst` elements (junctioned in)

---

## Critical Rules About Reference Repos

### Dakota & gnome-build-meta are authoritative

**NEVER invent workarounds for build issues.** For any infrastructure, bootc, systemd, kernel, or non-KDE/QT packages:

1. **FIRST**: Clone and examine `/var/home/james/reference-repos/dakota` and `/var/home/james/reference-repos/gnome-build-meta`
2. **ALWAYS**: Copy the `.bst` patterns and approaches from these known-good repos
3. **NEVER**: Use pre-built binaries, shortcuts, or workarounds to bypass build failures
4. **EXAMPLE**: When bootc compilation fails with Cargo DNS errors:
   - Don't create a bootc import element with a pre-built binary ❌
   - Instead, examine how Dakota/gnome-build-meta compile bootc in their CI ✓
   - Copy their exact `.bst` configuration and build infrastructure

### Reference Sources

| Situation | Reference |
|-----------|-----------|
| Bootc build issues | Dakota CI config + gnome-build-meta |
| Boot infrastructure (systemd-boot, fwupd, initramfs) | gnome-build-meta |
| OCI composition, layering, or export | Dakota's oci/ elements |
| Non-KDE package configuration | gnome-build-meta |
| KDE package cmake flags, dependencies | Arch Linux PKGBUILD |

### Bootc Handling

Bootc is a critical tool for creating bootable OCI images. It is compiled from source (Rust, ~400 Cargo dependencies) in:
- `gnome-build-meta`: https://gitlab.gnome.org/GNOME/gnome-build-meta (canonical reference)
- `projectbluefin/dakota`: https://github.com/projectbluefin/dakota (proven working setup)

If bootc build fails in the containerized BuildStream environment:
1. Check Dakota's and gnome-build-meta's CI/build configuration (`*.yml` in `.gitlab-ci/` or `.github/workflows/`)
2. Determine if they resolve DNS/Cargo issues via container networking or CI environment setup
3. Apply the same approach rather than using a pre-built binary

**Reference files**:
- `/var/home/james/reference-repos/gnome-build-meta/elements/gnomeos-deps/bootc.bst`
- `/var/home/james/reference-repos/dakota/elements/*/bootc.bst` (if exists)

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

## Build Commands (Use `just`)

**MANDATORY**: Always use the `just` recipes for running any `bst` (BuildStream) or diagnostic commands. The `Justfile` wraps BuildStream inside a pinned container image with correct volume mounts and permissions to ensure reproducibility.

```bash
# Recommended: Background build with logging and tail
just bst-build

# Foreground build + OCI export
just build

# Arbitrary BuildStream command (shell, show, checkout, etc.)
just bst <command> <args>

# Example: Run shell in a sandbox
just bst shell oci/tromso.bst

# View logs
just log
```

- **NEVER** run `bst` directly on the host or via `pipx` for project work.
- Never use `just bst-build` directly in a blocking tool call — it uses `tail -f`.
- The build container image is pinned in `Justfile` for reproducibility.
- Build log location: `/var/tmp/aurora-build.log`

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
   # Clear ONLY the failed element to preserve cache for unrelated elements
   rm -rf ~/.cache/buildstream/artifacts/refs/gnome/kde-CATEGORY-ELEMENT/
   rm -rf ~/.cache/buildstream/logs/gnome/kde-CATEGORY-ELEMENT/
   ```
   **⚠️ CRITICAL**: Never clear `kde-*` broadly — this forces rebuild of ALL KDE elements, not just the fix.
   Instead, clear only the specific element that failed.

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

## File locations

- **Reference repos**: `/var/home/james/reference-repos/`
  - `dakota/` — Project Bluefin Dakota (GNOME-based, bootc-enabled)
  - `gnome-build-meta/` — GNOME's BuildStream repository
- **Build logs**: `/var/tmp/aurora-build.log`
- **Cache**: `~/.cache/buildstream/`
- **This project**: `/var/home/james/dev/tromso/`

---

## VM & Graphical Boot Troubleshooting

### Systemd Ordering Cycles
If the VM hangs or boots to an emergency shell with "Ordering cycle found" messages in the serial log:
- Check `elements/tromso/system-config.bst`.
- **NEVER** use `Before=basic.target` on core services like `dbus.service`. This is a common source of cycles that causes D-Bus to be skipped, breaking SDDM and other dependencies.

### SDDM & Graphical Target
To ensure the system boots to a KDE login:
1. **Explicit Enablement**: SDDM must be explicitly enabled in `elements/tromso/system-config.bst` by creating symlinks for `display-manager.service` and adding `sddm.service` to `graphical.target.wants`.
2. **Default Target**: The default systemd target should be symlinked to `graphical.target`.
3. **Dependencies**: SDDM requires `accountsservice` (`kde-build-meta.bst:core-deps/accountsservice.bst`) to list users and manage sessions. Ensure it is in `elements/tromso/deps.bst`.
4. **Software Rendering**: In virtualized environments (libvirt/QEMU), SDDM may fail to start with GPU errors. Add a systemd drop-in for `sddm.service` setting `Environment=QT_QUICK_BACKEND=software` to use the software rasterizer.

### Linker Cache (`ldconfig`)
The composed OCI image requires a fresh linker cache for SDDM to resolve Qt6 libraries at boot:
- Use `chroot /layer ldconfig` or `ldconfig -r /layer -f /layer/etc/ld.so.conf` in `elements/oci/tromso.bst`.
- Omit `-C /etc/ld.so.cache` if it causes "need absolute file name" errors.

### Disk Image Corruption (Loop Devices)
When generating bootable images with `bootc install`:
- **Avoid Sparse Files**: `truncate` followed by `bootc` on loop devices can lead to metadata corruption (especially on EXT4).
- **Use `fallocate`**: Always pre-allocate the full disk size using `fallocate -l 30G bootable.raw`.
- **Prefer XFS**: For the bootable image filesystem, XFS has shown better resilience than EXT4 in this specific loopback deployment workflow.
- **Syncing**: Always `sync` before detaching loop devices or starting the VM.

---

## How to Use This (AI Assistant Mandate)

When you are asked to fix a build failure, add a package, or resolve an infrastructure issue:

1. **DO NOT** search the web or guess at solutions.
2. **DO** read the reference repo files from `/var/home/james/reference-repos/`.
3. **DO** compare the working configuration in Dakota/gnome-build-meta to the Aurora configuration.
4. **DO** apply the exact pattern or approach used in the reference repos.
5. **DO** document the reasoning in memory or commit messages.

---

## ISO Installer (tuna-os/tromso-iso)

The live ISO installer (`tuna-os/tromso-iso`) uses `tuna-installer` (fisherman backend) to install Aurora KDE Linux.  It is modeled on `projectbluefin/dakota-iso` and must stay in sync with that project's patterns.

### composeFsBackend and bootupd

**Always use `composeFsBackend: true` in the fisherman recipe.**

When `composeFsBackend: true`:
- fisherman exports the OCI image to an OCI layout on the TARGET DISK scratch (`/var/tmp`) before calling bootc
- bootc receives `--composefs-backend --source-imgref oci:/var/tmp/oci-cache`  
- The `-v /var/lib/containers:/var/lib/containers` bind-mount is **NOT** passed to the container
- bootc does **NOT** check for `bootupd` in this code path
- The install works without `bootupd` being present in the image (same as dakota)

**Do NOT use `composeFsBackend: false`.**  That path requires `bootupd` (specifically `bootupctl`) which is not shipped in the tromso image.

### OCI Layer Compression

The tromso OCI image must have gzip-compressed layers for composefs to work:
- Set `gzip: gzip` in `elements/oci/tromso.bst` (NOT `gzip: disabled`)
- `gzip: disabled` produces uncompressed layers that cause bootc's composefs splitstream to deadlock
- In the ISO build, force gzip re-compression when exporting: `skopeo copy --dest-compress-format gzip --dest-force-compress-format`

### VFS Containers-Storage in Squashfs

The squashfs embeds the tromso OCI image as VFS containers-storage.  The skopeo import into VFS **must run from inside the installer container** (not the build host) so the tar-split metadata is written in the format the live ISO can read.  See dakota-iso's justfile comment for details.

### Key Reference: `/var/home/james/reference-repos/dakota-iso/`

Always check dakota-iso for the correct behavior before making changes to tromso-iso.
