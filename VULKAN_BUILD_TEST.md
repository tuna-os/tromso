# Vulkan Support Testing - 2026-04-26

## Status: In Progress

**Added**: `vulkan-headers.bst` to KWin build-depends (commit 3e1c08930)

**Testing approach**:
- Let current plasma-workspace build proceed
- If KWin compiles successfully with Vulkan headers: **KEEP** Vulkan support
- If KWin fails: remove Vulkan headers and retry

**Current build state**: Still pulling artifacts, hasn't reached KWin compilation yet

## Next Steps After Build Completes

### If Vulkan Build Succeeds ✅
1. Keep vulkan-headers in KWin's build-depends
2. Optionally add to plasma-desktop as well
3. Document Vulkan support enabled

### If Vulkan Build Fails ❌
1. Remove vulkan-headers from KWin
2. Commit as "Revert Vulkan support - not compatible"
3. Continue with non-Vulkan build

## References
- Vulkan headers from: `freedesktop-sdk.bst:components/vulkan-headers.bst`
- KWin typically auto-detects Vulkan if headers available
- No special cmake flags needed for Vulkan detection
