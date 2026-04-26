# Plasma-Desktop X11 Support Changes

**Status**: Prepared changes (pending plasma-workspace success)

## Changes Needed in plasma-desktop.bst

Once plasma-workspace builds successfully with X11 support enabled, plasma-desktop needs parallel updates:

### 1. Un-comment KWin Dependency (line 12)
```
# OLD:
# - kde/plasma/kwin.bst  # Disabled: X11 dependencies

# NEW:
- kde/plasma/kwin.bst
```

### 2. Enable X11 Support (line 70)
```
# OLD:
-DWITH_X11=OFF

# NEW:
-DWITH_X11=ON
```

### 3. Re-enable X11 KCM Modules (lines 67-69)
```
# OLD (disabled):
-DBUILD_KCM_TABLET=OFF
-DBUILD_KCM_MOUSE_X11=OFF
-DBUILD_KCM_TOUCHPAD_X11=OFF

# NEW (enabled):
-DBUILD_KCM_TABLET=ON
-DBUILD_KCM_MOUSE_X11=ON
-DBUILD_KCM_TOUCHPAD_X11=ON
```

## Rationale
- KWin now has X11 support enabled with proper library dependencies
- plasma-desktop needs to be aware of X11 for settings modules
- X11 KCM (configuration) modules provide mouse/touchpad X11 settings

## Execution Timing
- Execute these changes AFTER plasma-workspace builds successfully
- Then build plasma-desktop to verify it compiles with X11
- Then proceed to full Aurora OCI build
