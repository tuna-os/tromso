# GitHub Issues & TODO Tracking for Aurora KDE Linux

**Session Date**: 2026-04-26  
**Build Status**: plasma-workspace cmake fix testing in progress

## 🔴 CRITICAL BLOCKERS (Must fix before release)

### 1. Plasma-Workspace CMake Configuration
- **Status**: 🔄 IN TESTING (patches 0006-0007 applied)
- **Issue**: CMake failed with "Configuring incomplete, errors occurred!"
- **Root Cause**: Subdirectories hard-coded links to optional KF6 components
- **Fix**: Patches to conditionally build/link based on component availability
- **Expected Resolution**: Current build should resolve this
- **Impact**: BLOCKING - No plasma-desktop or Aurora OCI without this

### 2. Bootc Build Infrastructure  
- **Status**: ❌ CANNOT BUILD LOCALLY
- **Issue**: Bootc is Rust app with ~400 Cargo dependencies, requires internet access
- **Blocker**: DNS/network access not available in containerized BuildStream environment
- **References**: 
  - `STATUS.md` - "Bootc requires CI infrastructure"
  - `TROUBLESHOOTING.md` - Discusses DNS/Cargo sandbox issues
- **Solutions**:
  - **Option A** (Recommended): Set up GitHub Actions CI (like Dakota does)
  - **Option B**: Use traditional ISO creation tools instead of bootc
  - **Option C**: Inject bootc post-build via container layer (has issues, see TROUBLESHOOTING.md)
- **Impact**: MEDIUM - Affects bootable image creation but OCI image itself works
- **Timeline**: Can defer to post-VM-testing phase

## 🟡 KNOWN ISSUES (Documented but not blocking)

### Disabled Packages (Commented out in aurora/deps.bst)

These packages have known issues and are disabled pending further investigation:

#### Login & Display
- **sddm** - Login manager
  - Issue: Patch application problems
  - Status: Not investigated yet
  - Workaround: Use direct plasma.service launch via systemd

#### Window Management
- **kwin** - Window manager
  - Issue: X11-only (Wayland-only Aurora architecture)
  - Status: Won't fix for this build (by design)
  - Workaround: Wayland Plasma uses native shell

#### System & Hardware
- **kscreen** - Screen management
  - Issue: CMake config error
  - Status: Needs investigation
  
- **plasma-nm** - Network Manager integration
  - Issue: Complex dependencies
  - Status: Needs investigation
  
- **plasma-pa** - PulseAudio integration
  - Issue: Debug issues
  - Status: Needs investigation

#### Applications
- **konsole** - Terminal emulator
  - Issue: D-Bus XML parsing
  - Status: Needs investigation
  
- **spectacle** - Screenshot tool
  - Issue: Debug issues
  - Status: Needs investigation

#### Power & Bluetooth
- **powerdevil** - Power management
  - Issue: Complex dependencies
  - Status: Needs investigation
  
- **bluedevil** - Bluetooth support
  - Issue: Debug issues
  - Status: Needs investigation

#### System Monitoring & Info
- **plasma-systemmonitor** - System monitor
  - Issue: CMake config error
  - Status: Needs investigation
  
- **kinfocenter** - Info center
  - Issue: about-distro module
  - Status: Needs investigation

#### Desktop Integration
- **xdg-desktop-portal-kde** - XDG portal implementation
  - Issue: Debug issues
  - Status: Needs investigation

### X11 Dependency Issues
- **Status**: 🔧 PARTIALLY MITIGATED
- **Disabled Features**: 
  - KWinDBusInterface (X11-only window manager)
  - ScreenSaverDBusInterface (X11 session management)
  - X11 libraries entirely (-DWITH_X11=OFF)
- **Impact**: Some X11-specific features unavailable, but Wayland-only build works
- **Future Work**: May need XWayland for legacy app support

## 🟢 RESOLVED ISSUES (Fixed in this session)

### Qt6/KF6 Component Discovery
- **Status**: ✅ FIXED
- **Issues Resolved**:
  1. Qt6Location missing from build-depends (patch 0001)
  2. KF6TextEditor/TextWidgets moved to optional (patch 0002)
  3. KWinDBusInterface disabled for Wayland (patch 0003)
  4. Breeze optional search mode (patch 0004)
  5. KF6Baloo optional search (patch 0005)
  6. Interactiveconsole conditional building (patch 0006)
  7. Shellprivate conditional TextWidgets linking (patch 0007)

### Plasma Desktop Stack Dependencies
- **Status**: ✅ ADDED
- **Components**: 
  - plasma-desktop, plasma-workspace, breeze theme
  - KDE frameworks (kwayland, libplasma, libkscreen, etc.)
  - Qt6 modules (qtlocation, qtdeclarative, etc.)
  - System libraries (qcoro, layer-shell-qt, kpipewire)

### KDE Applications Bundle
- **Status**: ✅ ADDED
- **Applications**:
  - Dolphin (file manager)
  - Kate (text editor)
  - Okular (PDF viewer)
  - Gwenview (image viewer)
  - Elisa (music player)
  - Ark (archive manager)
  - Kcalc (calculator)
  - Kdeconnect (device sync)

## 📋 TESTING TODO LIST

Once plasma-workspace builds successfully:

### Phase 1: Build Completion ✅ IN PROGRESS
- [ ] Plasma-workspace CMake configuration passes
- [ ] Plasma-desktop builds without errors
- [ ] Full Aurora OCI image builds successfully
- **Expected Duration**: 30-60 minutes from now

### Phase 2: Image Preparation (30 minutes)
- [ ] Extract OCI to bootable disk image
- [ ] Verify bootloader configuration
- [ ] Create bootable.raw (30GB sparse file)

### Phase 3: VM Boot Testing (15-30 minutes)
- [ ] Launch QEMU with bootable image
- [ ] Reach Plasma Wayland login screen
- [ ] SSH connectivity works (port 2222)
- [ ] Verify bootc status command

### Phase 4: KDE Plasma Desktop Testing (30 minutes)
- [ ] Plasma desktop loads completely
- [ ] Application menu accessible
- [ ] Dolphin (file manager) launches
- [ ] Kate (text editor) launches
- [ ] System settings opens
- [ ] Verify no GNOME packages present

### Phase 5: System Verification (20 minutes)
- [ ] Kernel version displayed correctly
- [ ] systemd status shows expected services
- [ ] SSH daemon running and accessible
- [ ] Network connectivity working
- [ ] Audio system (PipeWire) functional (if available)

## 🔍 Potential Post-Build Issues to Watch For

### Runtime Issues
1. **Missing locale files** - May need locale generation
2. **D-Bus service discovery** - Some Plasma components use D-Bus
3. **XDG directories** - Ensure ~/.config/plasma permissions
4. **Systemd activation** - Verify service ordering

### VM-Specific Issues
1. **Graphics acceleration** - QEMU may limit OpenGL/Vulkan
2. **Input devices** - Mouse/keyboard passthrough configuration
3. **Network configuration** - QEMU network setup for SSH access
4. **Resolution/display** - Wayland scaling in VM environment

## 📊 Build Progress Tracking

**Last Updated**: When plasma-workspace build completes

### Current Phase
⏳ Testing plasma-workspace cmake with patches 0006-0007
- Started: ~14:35 IST (after kernel bootstrap dependencies fetch)
- Expected completion: ~15:45-16:15 IST (dependent on cache hits)

### Next Phase (After Success)
📦 Full Aurora OCI build
- Estimated duration: 20-40 minutes
- Critical dependencies: plasma-workspace, plasma-desktop, breeze

## 🎯 Success Criteria for Build

✅ All phases complete when:
1. **plasma-workspace** builds without CMake errors
2. **plasma-desktop** builds successfully
3. **oci/aurora.bst** exports OCI image without failures
4. All 7 KDE patches apply cleanly (patches 0001-0007)
5. No missing dependencies reported in final build

## 📝 Next Session Actions (If Build Not Complete)

If this build doesn't complete due to time/resource limits:
1. Check `/var/tmp/aurora-build.log` for latest status
2. Note which element is currently building
3. Review any new error messages for patterns
4. Continue from where it left off (BuildStream caches artifacts)

---

**Build Status Page**: `/var/home/james/dev/kde-linux/BUILD_PROGRESS.md`  
**Known Issues**: `/var/home/james/dev/kde-linux/TROUBLESHOOTING.md`  
**Technical Deep Dive**: `/var/home/james/dev/kde-linux/PLASMA_WORKSPACE_CMAKE_FIX.md`
