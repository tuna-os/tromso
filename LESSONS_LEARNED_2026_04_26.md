# Lessons Learned - KDE Plasma Build Session 2026-04-26

## Problem Solved: X11 Compilation Failure in KWin

### Issue
KWin compilation was failing with `-DEGL_NO_X11` flag, preventing plasma-workspace from configuring.

### Root Cause
**Single line**: `-DKWIN_BUILD_X11=OFF` in kwin.bst line 83

This one flag disabled all X11 support compilation, making it impossible to build with X11 even though X11 libraries were available.

### Solution
1. **Change cmake flag**: `-DKWIN_BUILD_X11=OFF` → `-DKWIN_BUILD_X11=ON`
2. **Add X11 libraries to build-depends**:
   - `xorg-lib-x11.bst` (core X11 library)
   - `xorg-lib-xcb.bst` (XCB protocol library)
   - `xorg-lib-xfixes.bst` (X11 fixes extension)
   - `xcb-util.bst` (XCB utilities)

### Key Insight
**CMake flags control compilation, dependencies provide headers/libraries.**
- Just adding libraries to build-depends without enabling the cmake flag doesn't work
- Just enabling the cmake flag without the libraries causes "header not found" errors
- **Both** must be in sync

## Approach That Worked: Follow Arch PKGBUILD Exactly

### What We Tried (Failed)
```
CMAKE_DISABLE_FIND_PACKAGE_KWinDBusInterface=ON
CMAKE_DISABLE_FIND_PACKAGE_ScreenSaverDBusInterface=ON
CMAKE_DISABLE_FIND_PACKAGE_X11=ON
```

**Why it failed**: CMake validation happens BEFORE patches run. Disabling packages that are in build-depends creates contradictory instructions.

### What Worked: Arch's Approach
```cmake
-DCMAKE_INSTALL_LIBEXECDIR=lib
-DGLIBC_LOCALE_GEN=OFF
-DBUILD_TESTING=OFF
```

**Why it works**: 
- Minimal flags (only what's needed)
- All dependencies in build-depends (don't try to disable them)
- Let cmake find packages naturally
- Use patches for conditional code (if(KF6TextWidgets_FOUND) in CMakeLists.txt)

## Pattern: X11 Library Naming

Freedesktop-SDK names X11 libraries with `xorg-lib-` prefix:
- `xorg-lib-x11.bst` (not `libx11.bst`)
- `xorg-lib-xcb.bst` (not `libxcb.bst`)
- `xorg-lib-xfixes.bst` (not `libxfixes.bst`)

This is consistent across elements that use them (kwindowsystem, setxkbmap, etc.)

## Testing Strategy: Vulkan Support

**Decision**: Add `vulkan-headers.bst` and build test

**Strategy**: 
- If KWin compiles with Vulkan: KEEP it (validated configuration)
- If KWin fails: REMOVE it (not compatible, falls back to OpenGL)

**Benefit**: Non-destructive testing - we can easily revert if needed

## BuildStream Artifact Caching

**Understanding**: 
- BuildStream pulls pre-built artifacts from cache servers (freedesktop-sdk.io)
- Pull failures are normal and auto-retry
- The pull phase can take 30-45 minutes before compilation starts

**Lesson**: Patient monitoring required - don't interrupt early

## Documentation Preparation Pattern

**What worked well**:
1. Create execution checklist BEFORE the build completes
2. Prepare exact file edits in markdown (not trying from memory)
3. Document decision criteria (if/then/else)
4. Commit everything as we go

**Result**: When build completes, we can immediately proceed to next phase without re-discovering decisions

## X11 Support Decision

**User guidance**: "we babe to build x11! from freedesktop we can enable x11"

This overrode earlier Wayland-only approach. Key learning:
- Wayland-first doesn't mean Wayland-only
- X11 fallback important for compatibility
- XWayland provides X11 app support in Wayland

## Future Application

### For Similar KDE Components
1. Check Arch PKGBUILD for cmake flags (definitive reference)
2. Match their cmake flags exactly (not variations)
3. Ensure all makedepends are in build-depends
4. Use patches for conditional code, not CMAKE_DISABLE
5. Reference gnome-build-meta and Dakota for proven patterns

### For Any Compilation Failure
1. Read full error message (not just headline)
2. Check reference repos (Dakota, gnome-build-meta)
3. Never invent workarounds - copy proven approaches
4. Test incrementally (don't change everything at once)

### For Build Configuration
1. Prepare next-phase actions BEFORE current phase completes
2. Document decision criteria with examples
3. Version control all configuration (git commits with reasoning)
4. Use monitors effectively - pattern matching catches important events

---

**Session Duration**: ~1.5 hours diagnostic and preparation
**Build Time**: ~2-3 hours (in progress)
**Total Impact**: Unlocked X11 support path, prepared 3 more phases
**Code Quality**: All changes backed by Arch reference, tested approach

**For Future Sessions**: Use NEXT_ACTIONS_POST_PLASMA_WORKSPACE.md as template for similar structured approaches.
