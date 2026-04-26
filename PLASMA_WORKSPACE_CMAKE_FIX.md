# Plasma-Workspace CMake Configuration Fix

## Problem Statement

When building `plasma-workspace` (KDE Plasma 6.6) in a Wayland-only Aurora environment, the CMake configuration failed with:

```
-- Configuring incomplete, errors occurred!
```

Even though `KF6TextEditor` and `KF6TextWidgets` were explicitly listed in `build-depends` and patches were applied to move them from REQUIRED to OPTIONAL_COMPONENTS.

## Root Cause Analysis

The issue was NOT in the main `CMakeLists.txt`, but in subdirectories that unconditionally linked against these components without checking if they were found:

### 1. **interactiveconsole/CMakeLists.txt** (Line 10)
```cmake
target_link_libraries(plasma-interactiveconsole 
    Qt::Widgets Qt::DBus KF6::I18n KF6::KIOCore 
    KF6::WidgetsAddons 
    KF6::TextEditor              # <-- Hard-coded link!
    KF6::Package 
    KF6::TextWidgets             # <-- Hard-coded link!
)
```

### 2. **components/shellprivate/CMakeLists.txt** (Line 24)
```cmake
target_link_libraries(plasmashellprivateplugin PRIVATE
    ...
    KF6::TextWidgets             # <-- Hard-coded link!
    KF6::Package
)
```

When `KF6TextEditor` and `KF6TextWidgets` were moved to OPTIONAL_COMPONENTS and not found (because they're only used by these two subdirectories), CMake tried to link against non-existent targets, resulting in a fatal error.

## Solution

Created two additional patches to make these subdirectories conditional:

### Patch 0006: `make-interactiveconsole-optional.patch`
Wraps the `add_subdirectory(interactiveconsole)` call with a conditional check:

```cmake
if (KF6TextEditor_FOUND AND KF6TextWidgets_FOUND)
  add_subdirectory(interactiveconsole)
endif()
```

**Result**: Plasma-workspace builds without the interactive console if components aren't available.

### Patch 0007: `make-shellprivate-textwidgets-optional.patch`
Removes `KF6::TextWidgets` from the main `target_link_libraries()` call and conditionally adds it back:

```cmake
# Remove from main target_link_libraries
if (KF6TextWidgets_FOUND)
    target_link_libraries(plasmashellprivateplugin PRIVATE KF6::TextWidgets)
endif()
```

**Result**: shellprivate compiles without the optional widget support if not available.

## CMake Pattern Lesson

When moving components from REQUIRED to OPTIONAL_COMPONENTS:
1. Update main `find_package()` call ✓
2. Add CMAKE_DISABLE_FIND_PACKAGE flags for items that can't be optional ✓
3. **Also check subdirectories for hard-coded links** ← This was the missing step!

Subdirectories often hard-code links/dependencies without checking if they were found. Code that assumes "if find_package succeeded, the targets exist" will fail when components become optional.

## Testing Approach

1. Build `kde-build-meta.bst:kde/plasma/plasma-workspace.bst` alone
2. Verify CMake succeeds (no "Configuring incomplete" error)
3. Proceed to full Aurora OCI build

## Files Modified

- `kde-build-meta-local/patches/plasma-workspace/0006-make-interactiveconsole-optional.patch` (new)
- `kde-build-meta-local/patches/plasma-workspace/0007-make-shellprivate-textwidgets-optional.patch` (new)
- `kde-build-meta-local/elements/kde/plasma/plasma-workspace.bst` (patches list updated)

## Status

✅ Patches created and added to build configuration  
⏳ Testing build in progress (see monitor task)

Expected outcome: plasma-workspace CMake configures successfully, allowing full Aurora build to proceed.
