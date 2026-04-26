# Aurora KDE Build — Next Steps

**Status**: Plasma-workspace cmake fixes in testing (patches 0006-0007)

## 🎯 Immediate Goals (Order of Execution)

### 1. ✅ Resolve plasma-workspace CMake Configuration
- **Current Status**: Testing patches 0006 (interactiveconsole) and 0007 (shellprivate)
- **Expected Outcome**: plasma-workspace CMake configures without "Configuring incomplete" error
- **Next Action**: Wait for build result; if successful, proceed to #2

### 2. ⏳ Build plasma-desktop and Full Aurora OCI
- **Depends on**: #1 succeeding
- **Action**: `just build` to compile full OCI image with KDE Plasma
- **Expected Timeline**: 30-60 minutes for full build
- **Success Criteria**: `oci/aurora.bst` builds without failures

### 3. 📋 Review Known Issues & Pending Work
- **Bootc Build**: Currently can't build bootc locally (Cargo DNS issues in container). Status document recommends CI/GitHub Actions or ISO-based approach
- **Disabled Packages**: Many KDE packages are commented out in deps.bst due to known issues:
  - sddm (login manager) - has patch application issues
  - kwin (window manager) - disabled for Wayland-only (X11 dependencies)
  - kscreen (screen management) - cmake config error
  - plasma-nm (network manager) - complex dependencies
  - plasma-pa (PulseAudio) - debug issues
  - konsole (terminal) - D-Bus XML parsing issues
  - spectacle (screenshot) - debug issues
  - powerdevil (power mgmt) - complex dependencies
  - plasma-systemmonitor - cmake config
  - kinfocenter - about-distro module
  - bluedevil (Bluetooth) - debug issues
  - xdg-desktop-portal-kde - debug issues

### 4. 🖥️ Generate Bootable Image & Test in VM
- **Prerequisites**: #2 complete
- **Commands**:
  ```bash
  just generate-bootable-image        # Create bootable.raw from OCI
  just boot-vm                        # Launch QEMU with bootable.raw
  ```
- **Test Plan**:
  - Boot completes to login screen (Plasma Wayland session)
  - SSH connection works (port 2222 on localhost)
  - KDE Plasma desktop loads
  - Basic app launch (Dolphin, Kate, etc.)

### 5. ✅ VM Testing Checklist
- [ ] System boots and reaches graphical login
- [ ] Plasma Wayland session launches
- [ ] Can SSH to VM (ssh -p 2222 root@127.0.0.1)
- [ ] Verify bootc present: `ssh -p 2222 root@127.0.0.1 'bootc status'`
- [ ] Verify kernel: `ssh -p 2222 root@127.0.0.1 'uname -a'`
- [ ] Verify SSH: `ssh -p 2222 root@127.0.0.1 'systemctl status sshd'`
- [ ] Launch file manager: Open Dolphin from application menu
- [ ] Launch text editor: Open Kate from application menu
- [ ] Check Plasma widgets and settings work
- [ ] Verify no GNOME packages loaded: `ssh -p 2222 root@127.0.0.1 'rpm -qa | grep -i gnome'` (should be empty)

### 6. 🚀 After Successful VM Boot
- **Clean up**: Document all successful package configs for future reference
- **Optional Enhancements**:
  - Re-enable disabled packages if testing shows they work
  - Create ISO image (bootc or traditional)
  - Set up proper SSH keys and hardening
  - Performance profiling / size optimization

## 📊 Build Artifacts to Track

- `/var/tmp/aurora-build.log` — Main build log
- `/var/home/james/dev/kde-linux/bootable.raw` — Bootable disk image (30GB)
- `/root/.cache/buildstream/` — BuildStream artifact cache

## 🔧 Known Technical Constraints

1. **Bootc requires CI environment** — Can't build locally due to Cargo DNS sandbox
   - Workaround: Use pre-built OCI or ISO approach
   - Long-term: Set up GitHub Actions CI (like Dakota does)

2. **Wayland-only architecture**
   - No X11/KWin (Wayland Plasma uses native shell)
   - Some KDE packages have X11 hard-requirements (kwin, kscreen)
   - Need to disable X11-only packages or patch them

3. **Plasma/Qt6 interdependencies**
   - Must explicitly list all Qt6 components in build-depends
   - CMake components don't transitively include cmake configs
   - Some packages moved to OPTIONAL_COMPONENTS but code wasn't adapted (patches 0006-0007)

## 📝 Build Flags Currently Set

```cmake
-DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
-DCMAKE_DISABLE_FIND_PACKAGE_KWinDBusInterface=ON
-DCMAKE_DISABLE_FIND_PACKAGE_ScreenSaverDBusInterface=ON
-DCMAKE_DISABLE_FIND_PACKAGE_X11=ON
-DCMAKE_DISABLE_FIND_PACKAGE_AppStreamQt=ON
-DCMAKE_DISABLE_FIND_PACKAGE_KExiv2Qt6=ON
-DWITH_X11=OFF
```

These skip X11-specific components and optional features that aren't available in containerized build environment.

---

**User's Explicit Request**: "We need to take a look at all GitHub issues and pending TODOS before we consider our build done. Then we move into booting it in a VM and verifying that KDE is properly running and setup."

**Current Plan Alignment**:
- ✅ #1: Fixing plasma-workspace cmake issues (current work)
- ✅ #2: Build full OCI with KDE Plasma (when #1 completes)
- ✅ #3: Review all disabled/known issues (documented above)
- ✅ #4: Boot in VM and test thoroughly
- ✅ #5: Verify KDE Plasma runs properly
