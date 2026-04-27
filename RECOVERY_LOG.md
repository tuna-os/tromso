# Build Failure Recovery Log

Automatically maintained by the pi recovery agent. Each entry documents a failure, the options considered, and the fix applied. Future recovery sessions read this file to avoid repeating analysis.

---


### [2026-04-26T20:10:09.883218] - FAILURE DETECTED

**Failing element(s):** [f404544d] kde-build-meta.bst:freedesktop-sdk.bst:components/asciidoctor.bst: Try #1 failed, retrying[0m, [2710e306] kde-build-meta.bst:freedesktop-sdk.bst:components/lvm2-stage1.bst: Try #1 failed, retrying[0m, [2d264fca] kde-build-meta.bst:core-deps/systemd-base.bst: Try #1 failed, retrying[0m
**Build log:** /root/.cache/buildstream/logs/gnome/kde-plasma-kwin/f835f6d5-build.20260426-143229.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T20:10:51.664825] - FAILURE DETECTED

**Failing element(s):** [f404544d] kde-build-meta.bst:freedesktop-sdk.bst:components/asciidoctor.bst: Try #1 failed, retrying[0m, [2710e306] kde-build-meta.bst:freedesktop-sdk.bst:components/lvm2-stage1.bst: Try #1 failed, retrying[0m, [2d264fca] kde-build-meta.bst:core-deps/systemd-base.bst: Try #1 failed, retrying[0m
**Build log:** /root/.cache/buildstream/logs/gnome/kde-plasma-kwin/f835f6d5-build.20260426-143229.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T20:42:30.483483] - FAILURE DETECTED

**Failing element(s):** [f404544d] kde-build-meta.bst:freedesktop-sdk.bst:components/asciidoctor.bst: Try #1 failed, retrying[0m, [2710e306] kde-build-meta.bst:freedesktop-sdk.bst:components/lvm2-stage1.bst: Try #1 failed, retrying[0m, [2d264fca] kde-build-meta.bst:core-deps/systemd-base.bst: Try #1 failed, retrying[0m
**Build log:** /root/.cache/buildstream/logs/gnome/kde-plasma-kwin/f835f6d5-build.20260426-143229.log
**Status:** PENDING — awaiting pi recovery agent

---

### [2026-04-26] - RESOLVED: kwin build failure — missing private Qt6 X11 header

The kwin build failed at step 659/1858 compiling `src/helpers/killer/killer.cpp` with `fatal error: private/qtx11extras_p.h: No such file or directory`, because that private Qt6 X11 extras header is not available in the BuildStream sandbox. The `.bst` file already carried `-DBUILD_WINDOW_KILLER=OFF` to skip the killer helper subdirectory, but the patch (`patches/kwin/0001-killer-no-x11.patch`) that introduces the `BUILD_WINDOW_KILLER` CMake option into `src/helpers/CMakeLists.txt` had been commented out in the sources section, rendering the cmake flag a no-op. Uncommenting the patch in `kde-build-meta-local/elements/kde/plasma/kwin.bst` restores the conditional build gate so that `-DBUILD_WINDOW_KILLER=OFF` takes effect and the killer subdirectory is excluded from the build entirely.

### [2026-04-26T22:41:38.627832] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/a26634c1-build.20260426-171131.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T22:58:39.237795] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/a26634c1-build.20260426-172024.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T23:17:18.587024] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/frameworks/kwindowsystem.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-frameworks-kwindowsystem/5cc5136a-build.20260426-174431.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T23:17:18.792590] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/frameworks/kwindowsystem.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-frameworks-kwindowsystem/5cc5136a-build.20260426-174431.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-26T23:29:12.095955] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/frameworks/kwindowsystem.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-frameworks-kwindowsystem/5cc5136a-build.20260426-174431.log
**Status:** PENDING — awaiting pi recovery agent

### kwindowsystem.bst — missing private/qtx11extras_p.h (2026-04-26)
**Error:** `fatal error: private/qtx11extras_p.h: No such file or directory` during kwindowsystem build. This private Qt6 header is part of the QtGui module and requires X11/XCB support to be generated. **Root cause:** The `qt6-qtbase.bst` override in kde-build-meta-local was missing X11/XCB build dependencies (`xorg-lib-x11`, `xorg-lib-xcb`, `xcb-util-*`, `libxkbcommon`) and the cmake options `-DQT_FEATURE_xcb=ON` and `-DQT_FEATURE_xcb_xlib=ON`. Without these, Qt6 was built without X11/XCB support, so the `qtx11extras_p.h` private header was never generated. **Fix:** Added the missing X11/XCB dependencies and cmake options to `kde/qt6/qt6-qtbase.bst` to match the staged junction configuration, ensuring Qt6 provides the required private headers for KDE frameworks like kwindowsystem that depend on X11 integration.

### [2026-04-27T04:44:27.687703] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands, kde-build-meta.bst:kde/qt6/qt6-qtsvg.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtsvg/ff4d4bd9-build.20260426-230928.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T04:44:28.485124] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands, kde-build-meta.bst:kde/qt6/qt6-qtsvg.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtsvg/ff4d4bd9-build.20260426-230928.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T04:44:29.453276] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands, kde-build-meta.bst:kde/qt6/qt6-qtsvg.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtsvg/ff4d4bd9-build.20260426-230928.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T04:44:32.348563] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands, kde-build-meta.bst:kde/qt6/qt6-qtsvg.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtsvg/ff4d4bd9-build.20260426-230928.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T05:36:50.855001] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-000645.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T05:36:51.784916] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-000645.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T05:36:52.583568] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-000645.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T05:37:21.761376] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-000645.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T05:37:23.456035] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-000645.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T07:01:54.487176] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/qt6/qt6-qtshadertools.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-qt6-qt6-qtshadertools/53c0ecc5-build.20260427-013148.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:27.787988] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:29.772217] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:30.748370] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:30.748247] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:31.221603] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:32.089916] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:16:32.456165] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b718b355-build.20260427-024625.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:33:21.312006] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:47:00.677702] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:47:02.658009] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:47:03.599513] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:47:04.059054] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T08:47:04.929555] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kwin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log
**Status:** PENDING — awaiting pi recovery agent

---

### kwin.bst — fatal error: netwm.h: No such file or directory (2026-04-27)
**Error:** `/buildstream/gnome/kde/plasma/kwin.bst/src/group.h:19:10: fatal error: netwm.h: No such file or directory`
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kwin/9ea3a9d9-build.20260427-030318.log

**Root cause:** `netwm.h` is a KDE Frameworks header provided by `KF6WindowSystem` (kwindowsystem) at `/usr/include/KF6/KWindowSystem/netwm.h`. It is generated by `ecm_generate_headers()` in the `KF6WindowSystemX11Plugin` and only installed when X11 support is enabled (`-DKWINDOWSYSTEM_X11=ON`).

Commit `f8d12c47c` had disabled X11 in kwindowsystem (`-DKWINDOWSYSTEM_X11=OFF`) to work around a qt6-qtbase private headers issue. However, the qt6-qtbase private headers (`private/qtx11extras_p.h`) are now available via the local `kde/qt6/qt6-qtbase.bst` build dependency (which builds Qt6 with X11/XCB support). The kwindowsystem.bst was modified on disk to re-enable X11 but not yet committed.

**Fix:** Committed the pending kwindowsystem.bst changes:
- Changed `-DKWINDOWSYSTEM_X11=OFF` to `-DKWINDOWSYSTEM_X11=ON`
- Moved X11 dependencies from `build-depends` to `depends` (xorg-lib-x11, xorg-lib-xcb) for proper runtime availability
- Cleared kwindowsystem and kwin artifact caches to force rebuild with X11 support

**Verification:** Verified that Arch Linux's `kwindowsystem` package installs `netwm.h` at `usr/include/KF6/KWindowSystem/netwm.h`. The header is part of the X11 plugin and requires `KWINDOWSYSTEM_X11=ON`.

**Files changed:** `kde-build-meta-local/elements/kde/frameworks/kwindowsystem.bst` (commit 62837909b)
**Artifacts cleared:** kwindowsystem, kwin

### [2026-04-27T10:24:43.946845] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:44.873206] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:45.704465] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:46.663302] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:46.668990] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:47.080931] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:47.630354] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:24:48.521124] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch, kde-build-meta.bst:kde/apps/dolphin.bst: Running commands
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045256.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:35.334396] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:36.259755] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:37.093801] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:38.061645] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:38.472906] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:39.010625] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:29:39.902654] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:39:51.851573] - FAILURE DETECTED

**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0001-optional-x11.patch
**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-kscreenlocker/b659676f-fetch.20260427-045629.log
**Status:** PENDING — awaiting pi recovery agent

### [2026-04-27T10:52:16.242042] - FAILURE DETECTED (PENDING)
**Failing element(s):** kde-build-meta.bst:kde/plasma/kscreenlocker.bst: Applying local patch: patches/kscreenlocker/0004-guard-qx11application.patch
**Build log:** /var/tmp/aurora-build.log

### kscreenlocker.bst — redundant patch 0004 (2026-04-27)
**Error:** `Reversed (or previously applied) patch detected!` when applying `patches/kscreenlocker/0004-guard-qx11application.patch` on `greeter/greeterapp.cpp`. Patch 0004 wraps the `QX11Application` usage with `#ifdef HAVE_X11` in `greeter/greeterapp.cpp`, but patch 0001 (`0001-optional-x11.patch`) already contains the exact same change. The two patches conflict because 0001 was expanded to include the greeter X11 guard that 0004 was originally created for.
**Fix:** Removed the `0004-guard-qx11application.patch` entry from `kde-build-meta-local/elements/kde/plasma/kscreenlocker.bst` since it is fully subsumed by patch 0001.
**Files changed:** `kde-build-meta-local/elements/kde/plasma/kscreenlocker.bst` (commit 22840f82a)
**Artifacts cleared:** kscreenlocker

---

### [2026-04-27] - RESOLVED: kscreenlocker build failure — malformed patch at line 400

The kscreenlocker build failed with `/usr/sbin/patch: *** malformed patch at line 400: 'return false;'` in `patches/kscreenlocker/0001-optional-x11.patch`. The patch was malformed because it was generated against an older version of the source code and no longer matched the current commit (093598fd on Plasma/6.6).

**Root cause:** The patches (`0001-optional-x11.patch`, `0002-fix-x11info-ctor.patch`, `0003-add-source-include-for-fixx11h.patch`, `0004-guard-qx11application.patch`) and the `override/` directory were created to make X11 optional in kscreenlocker. However, X11 is already a build dependency via `xorg-lib-x11.bst`, `xorg-lib-xcb.bst`, and `xcb-util-keysyms.bst`. The patches are unnecessary and were causing build failures.

**Fix:** Removed all X11-optional patches from `kde-build-meta-local/elements/kde/plasma/kscreenlocker.bst` and deleted the patch files and override directory. The upstream source now builds with X11 fully available.

**Files changed:**
- Modified: `kde-build-meta-local/elements/kde/plasma/kscreenlocker.bst` (removed patch sources)
- Deleted: `patches/kscreenlocker/0001-optional-x11.patch`
- Deleted: `patches/kscreenlocker/0002-fix-x11info-ctor.patch`
- Deleted: `patches/kscreenlocker/0003-add-source-include-for-fixx11h.patch`
- Deleted: `patches/kscreenlocker/0004-guard-qx11application.patch`
- Deleted: `patches/kscreenlocker/override/fixx11h.h`
- Deleted: `patches/kscreenlocker/override/x11info.h`

**Lesson learned:** When X11 is already a build dependency, avoid adding patches that make it optional. Keep the build simple and use upstream code as-is.

---

### [2026-04-27] - RESOLVED: kwin build failure — undefined linker references to KF6Archive, KF6KIOCore, KF6KIOGui, KF6BreezeIcons

The kwin build failed at the final linking step for `bin/kwin_wayland` with
undefined references from transitive dependencies:

- `KArchiveEntry::name()`, `KArchiveDirectory::copyTo()`, `KCompressionDevice`, `KTar`, `KZip` — from `libKF6Archive.so.6` (needed by `libKF6Svg`, `libKF6Package`)
- `KIO::ApplicationLauncherJob`, `KIO::UntrustedProgramHandlerInterface` — from `libKF6KIOCore.so.6` / `libKF6KIOGui.so.6` (needed by `libKGlobalAccelD`)
- `BreezeIcons::initIcons()` — from `libKF6BreezeIcons.so.6` (needed by `libKF6IconThemes`)

**Root cause:** `karchive`, `kio`, and `breeze-icons` were not listed as build-depends in `kwin.bst`. They are transitive dependencies of libraries already linked (KF6Svg, KF6Package, KGlobalAccelD, KF6IconThemes), but without explicit build-depends their .so files weren't available at link time.

**Fix:** Added `kde/frameworks/karchive.bst`, `kde/frameworks/kio.bst`, and `kde/frameworks/breeze-icons.bst` to build-depends in `kde-build-meta-local/elements/kde/plasma/kwin.bst`.

**Lesson learned:** When a library links against another KDE library that has its own transitive dependencies, those transitive deps must also be declared as build-depends to ensure linker visibility.

---

### [2026-04-27] - X11/XCB PATCH CLEANUP (Systematic Fix)

**Failing element(s):** Multiple (libkscreen, libplasma, kdeconnect, kwin, dolphin, bluedevil, okular, plasma-workspace)

**Root cause:** All X11/XCB-related patches were workarounds for missing build-depends. Arch PKGBUILDs build all packages with X11 enabled and zero patches. Instead of patching to make X11 optional, the correct fix is to add X11/XCB libraries as build-depends.

**Fix applied:**
- **libkscreen**: Removed `0001-optional-xcb-dpms.patch`, removed `-DCMAKE_DISABLE_FIND_PACKAGE_XCB=ON`, added `xorg-lib-xcb.bst` + `xcb-util.bst`
- **libplasma**: Removed 4 KX11Extras guard patches, removed `-DWITHOUT_X11=ON`, added `xorg-lib-x11.bst` + `xorg-lib-xcb.bst` + `xcb-util.bst`
- **kdeconnect**: Removed 2 X11 notification patches, removed `-DWITH_X11=OFF`, added `xorg-lib-x11.bst` + `xorg-lib-xcb.bst` + `xorg-lib-xtst.bst` + `libei.bst` + `libevdev.bst`
- **kwin**: Removed `0001-killer-no-x11.patch`
- **dolphin**: Removed `0001-optional-x11.patch`
- **bluedevil**: Removed `0001-drop-x11-pin-activation.patch`
- **okular**: Removed `0001-optional-x11.patch` (kept `0002-dvi-qstringliteral.patch` — not X11-related)
- **plasma-workspace**: Added `xorg-lib-ice.bst` + `xorg-lib-sm.bst` for ksmserver (CMake failed with `X11_ICE_LIB=NOTFOUND`)
- **plasma5support**: Removed `fixx11h.h` override directory (not referenced by any .bst)

**Submodule commit:** `c59f819b6` (kde-build-meta-local), `a0bfd86` (main)

---

### [2026-04-27] - REMOVED ALL X11-DISABLING CMAKE FLAGS

**Packages affected:** kguiaddons, kdbusaddons, kglobalaccel, kjobwidgets, kio, kidletime, kstatusnotifieritem, kcrash, kglobalacceld, plasma5support, plasma-integration, plasma-desktop, gwenview

**Root cause:** `-DWITH_X11=OFF` / `-DWITHOUT_X11=ON` cmake flags were workarounds for missing X11 build-depends. Arch PKGBUILDs build all these packages with X11 enabled and zero X11-disabling flags.

**Fix applied:** Stripped all `-DWITH_X11=OFF`, `-DWITHOUT_X11=ON`, `-DBUILD_KCM_MOUSE_X11`, `-DBUILD_KCM_TOUCHPAD_X11`, and `-DCMAKE_DISABLE_FIND_PACKAGE_XCB` cmake flags from all .bst files.

**Submodule commit:** `b59ba045f` (kde-build-meta-local), `02d733f` (main)

---

### [2026-04-27] - KDECONNECT: Add libfakekey build-depend

**Failing element:** kde/apps/kdeconnect.bst

**Root cause:** CMake configure failed with `Could NOT find LibFakeKey` in `plugins/mousepad/CMakeLists.txt`. Arch PKGBUILD lists `libfakekey` as a dependency. Not previously in our build tree.

**Fix applied:**
- Created `core-deps/libfakekey.bst` (autotools, from github:veyon/libfakekey tag 0.3)
- Added `core-deps/libfakekey.bst` to `kdeconnect.bst` build-depends
- Also noted: KF6People is still missing but patched optional (warning only, not error)

**Submodule commit:** `8aaa219cb` (kde-build-meta-local), `daa2b4e` (main)

---

### [2026-04-27] - KDECONNECT: Fix libfakekey tar source `ref` key

**Failing element:** core-deps/libfakekey.bst

**Root cause:** BuildStream element resolution failed with `Unexpected key: sha256` at line 7 column 10. BuildStream's `kind: tar` sources require the `ref` key for checksums, not `sha256`.

**Fix applied:** Replaced `sha256` with `ref` in the tar source definition of `libfakekey.bst`.

**Submodule commit:** `5718b3548` (kde-build-meta-local), `0d733d1` (main)

---

### [2026-04-27] - PLASMA-WORKSPACE: Fix virtualkeyboard_interface.h missing

**Failing element:** kde/plasma/plasma-workspace.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-workspace/79797ffc-build.20260427-093910.log

**Root cause:** Compilation failed at `components/keyboardlayout/virtualkeyboard.h:11:10: fatal error: virtualkeyboard_interface.h: No such file or directory`. The existing patch `0003-skip-kwin-virtualkeyboard-dbus-interface.patch` only commented out the `qt_add_dbus_interface` call and the `target_sources` reference for virtualkeyboard files. However, `ecm_add_qml_module` auto-discovers all `.h` and `.cpp` files in the directory. So `virtualkeyboard.h` was still picked up by auto-discovery, and its `#include "virtualkeyboard_interface.h"` (which was never generated since the dbus interface call was commented out) caused a fatal compilation error when the qmltyperegistrations tried to include it.

**Fix applied:** Rewrote the patch to:
1. Remove the `qt_add_dbus_interface` call for `${KWIN_VIRTUALKEYBOARD_INTERFACE}` from CMakeLists.txt
2. Remove the `virtualkeyboard.cpp virtualkeyboard.h` line from `target_sources`
3. Delete `virtualkeyboard.cpp` and `virtualkeyboard.h` entirely so they are not auto-discovered by `ecm_add_qml_module`

**Submodule commit:** `21d77d8d5` (kde-build-meta-local), `9490249` (main)

---

### [2026-04-27] - PLASMA-WORKSPACE: Add libxslt build-depend for meinproc6

**Failing element:** kde/plasma/plasma-workspace.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-workspace/23dde748-build.20260427-103826.log

**Root cause:** `meinproc6` (from kdoctools) failed with `error while loading shared libraries: libxslt.so.1: cannot open shared object file`. kdoctools lists libxslt as a build-depend but the dependency is not propagated transitively. plasma-workspace invokes meinproc6 to process documentation files during build.

**Fix applied:** Added `freedesktop-sdk.bst:components/libxslt.bst` to `plasma-workspace.bst` build-depends.

**Submodule commit:** `09c7c4f9c` (kde-build-meta-local), `65fb8cb` (main)

---

### [2026-04-27] - PLASMA-WORKSPACE: Add docbook-xml/docbook-xsl and DTD paths

**Failing element:** kde/plasma/plasma-workspace.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-workspace/dffd61e1-build.20260427-110208.log

**Root cause:** `meinproc6` failed with `failed to load "file:///usr/share/xml/docbook/xml-dtd/4.5/docbookx.dtd": No such file or directory`. kdoctools has docbook-xml and docbook-xsl as build-depends but the DTD path cmake variables are not propagated to downstream elements. plasma-workspace invokes meinproc6 to process .docbook files.

**Fix applied:**
- Added `freedesktop-sdk.bst:components/docbook-xml.bst` and `freedesktop-sdk.bst:components/docbook-xsl.bst` to build-depends
- Added `-DDocBookXML4_DTD_DIR=/usr/share/xml/docbook/xml-dtd/4.5` and `-DDocBookXSL_DIR=/usr/share/xml/docbook/xml/xsl-stylesheets` to cmake-local

**Submodule commit:** `402fd7eb9` (kde-build-meta-local), `cf6a745` (main)

---

### [2026-04-27] - PLASMA-WORKSPACE: Add breeze-icons build-depend

**Failing element:** kde/plasma/plasma-workspace.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-workspace/6f53a9f0-build.20260427-111800.log

**Root cause:** Linker failed on bin/krunner with `undefined reference to BreezeIcons::initIcons()`. libKF6IconThemes.so.6 references BreezeIcons::initIcons() from breeze-icons. While kiconthemes depends on breeze-icons, the transitive dependency is not propagated for linker resolution.

**Fix applied:** Added `kde/frameworks/breeze-icons.bst` to build-depends.

**Submodule commit:** `93b8f3a3e` (kde-build-meta-local), `bf1fa9a` (main)

---

### [2026-04-27] - PLASMA-DESKTOP: Add qt6-qtsvg build-depend

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/b236f7f0-build.20260427-114632.log

**Root cause:** CMake configure failed with `Could NOT find Qt6Svg`. plasma-desktop requires Qt6Svg for SVG icon rendering.

**Fix applied:** Added `kde/qt6/qt6-qtsvg.bst` to build-depends.

**Submodule commit:** `4921ac064` (kde-build-meta-local), `c741292` (main)

---

### [2026-04-27] - PLASMA-DESKTOP: Add qt6-qt5compat build-depend

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/ec9fa807-build.20260427-121343.log

**Root cause:** CMake configure failed with `Could NOT find Qt6Core5Compat`. plasma-desktop requires Qt6Core5Compat for Qt5 compatibility utilities.

**Fix applied:** Added `kde/qt6/qt6-qt5compat.bst` to build-depends.

**Submodule commit:** `7283ec6f0` (kde-build-meta-local)

---

### [2026-04-27] - PLASMA-DESKTOP: Add missing Framework dependencies

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/2c0a397d-build.20260427-122136.log

**Root cause:** CMake configure failed with `Could NOT find KF6 (missing: XmlGui)`. plasma-desktop requires multiple KDE Framework libraries that were not declared as build-depends. Added kxmlgui, kdeclarative, kservice, kbookmarks, kcompletion, kitemviews, and kjobwidgets based on Arch PKGBUILD.

**Fix applied:** Added 7 KDE Framework build-depends to plasma-desktop.bst.

**Submodule commit:** `f4a1cad89` (kde-build-meta-local)

---

### [2026-04-27] - PLASMA-DESKTOP: Re-enable kwin build-depend

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/d16a7300-build.20260427-123042.log

**Root cause:** CMake configure failed with `Could not find package configuration file provided by "KWinDBusInterface"`. This package is provided by kwin. The kwin dependency was previously disabled due to X11 issues, but those are now resolved.

**Fix applied:** Re-enabled `kde/plasma/kwin.bst` build-depend (was commented out as `# - kde/plasma/kwin.bst  # Disabled: X11 dependencies`).

**Submodule commit:** `e8f15a007` (kde-build-meta-local)

---

### [2026-04-27] - PLASMA-DESKTOP: Add X11 dependencies for kcm_mouse

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/9d4fdde3-build.20260427-124209.log

**Root cause:** CMake configure failed with `Missing X11 dependencies for kcm_mouse: xorg-libinput;X11_Xi;X11_Xinput`. plasma-desktop requires X11 input libraries for the mouse configuration module.

**Fix applied:** Added `freedesktop-sdk.bst:components/xorg-lib-x11.bst`, `freedesktop-sdk.bst:components/xorg-lib-xi.bst`, and `freedesktop-sdk.bst:components/libinput.bst` to build-depends.

**Submodule commit:** `627b02a98` (kde-build-meta-local)

---

### [2026-04-27] - PLASMA-DESKTOP: Disable BUILD_KCM_MOUSE_X11

**Failing element:** kde/plasma/plasma-desktop.bst

**Build log:** /var/home/james/.cache/buildstream/logs/gnome/kde-plasma-plasma-desktop/dd009cdc-build.20260427-130707.log

**Root cause:** CMake configure failed with `Missing X11 dependencies for kcm_mouse: xorg-libinput`. The CMake checks for pkg-config module "xorg-libinput" but the actual module is "libinput". This is a CMake bug in plasma-desktop. Disabled X11 mouse KCM since this is a Wayland-only build.

**Fix applied:** Added `-DBUILD_KCM_MOUSE_X11=OFF` to cmake-local variables.

**Submodule commit:** `d9f943ca5` (kde-build-meta-local)
