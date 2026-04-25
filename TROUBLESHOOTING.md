# Aurora Bootable Disk — Troubleshooting & Findings

**Date:** 2026-04-25  
**Status:** Disk is **UNBOOTABLE** — Diagnosis complete

## What We Found

### Disk Status
- **bootable.raw:** Completely blank (all zeros) - 30GB sparse file
- **bootc install-to-disk:** Failed to write anything to disk
- **Error message:** "Multiple commit objects found" when trying to extract OCI image
- **Root cause:** OCI image structure corrupted by Dockerfile layer

### Why bootc Failed

1. **OCI Image Corruption:** 
   - Original `aurora:latest` created by BuildStream exports fine as OCI
   - Our Dockerfile SSH layer (`FROM aurora:latest + RUN commands`) created a malformed OCI structure
   - bootc couldn't parse the image to extract filesystem

2. **Missing bootc in Image:**
   - The Aurora OCI image doesn't have bootc built in
   - We tried to inject it post-build via Docker
   - bootc needs to be IN the image to use `bootc install-to-disk`

3. **Catch-22:**
   - bootc is meant to be in the image built with `bootc install` (run inside container)
   - We were trying to use `bootc install-to-disk` from outside the container
   - This requires bootc to already be in the image, which it isn't

## Root Cause Analysis

```
BuildStream OCI Export
    ↓
aurora:latest (2.86GB) ✓ WORKS
    ↓
Dockerfile layer: FROM aurora:latest + RUN
    ↓
aurora:ssh (corrupted OCI)
    ↓
bootc install-to-disk ✗ FAILS
    Error: "Multiple commit objects found" - can't parse image
    Result: Blank disk (0 bytes written)
```

## What Doesn't Work

❌ **bootc in Podman container** — bootc binary not in image  
❌ **bootc install-to-disk from host** — bootc not in image  
❌ **Dockerfile SSH layer** — Corrupts OCI structure  
❌ **Building with current BuildStream** — openssh.bst not picked up (cache issues)

## Why bootc Is Difficult Here

bootc is designed as:
```
1. Build OCI image with tooling (BuildStream, Dockerfile, etc.)
2. Image must INCLUDE bootc binary and all dependencies
3. Run `podman run <image> bootc install ...` from inside image
4. Container writes itself to target disk
```

Our problem:
- Aurora doesn't have bootc in its BuildStream definition (DNS/Cargo sandbox issues prevented adding it)
- We tried to inject bootc post-build (didn't work - failed with ostree lib issues)
- Can't use Dockerfile layer on top (corrupts OCI)
- Can't use host bootc without image having bootc (permissions/image structure)

## Possible Solutions

### Solution 1: Use Pre-built OCI Image with bootc
If we can find or create an OCI image that already has bootc built in and working:
```bash
bootc install-to-disk --filesystem ext4 /dev/vda
# Would work if image has bootc
```
**Status:** Dakota/Fedora Kinoite have this - could use as reference

### Solution 2: Use ISO Instead of bootc
Skip bootc entirely, use traditional:
- Live ISO (xorriso/mkisofs) with bootloader
- Fedora/Ubuntu ISO-building tools
- Or: Build OCI, extract rootfs, use it directly

**Estimated effort:** 1-2 hours  
**Reliability:** High (proven approach)

### Solution 3: Get bootc Working in BuildStream
Fix the original openssh.bst issue:
1. BuildStream cache is stubborn (cleared 132GB but cache server has copy)
2. Could wait 24-48 hours for natural cache expiry
3. Or: Manually rebuild dependencies with new hash touching

**Estimated effort:** 30+ minutes  
**Reliability:** Medium (BuildStream caching still a problem)

### Solution 4: Use Dakota Image as Base
If Dakota (Fedora Kinoite flavor) has working bootc:
- Use their OCI as base
- Add KDE customizations
- Run bootc install-to-disk

**Estimated effort:** Unknown (need to investigate)

## Recommendation

**Best path forward:** Option 2 (ISO) or Option 4 (Dakota base)

**Option 2** is most straightforward:
1. Extract Aurora OCI rootfs to directory
2. Add bootloader (UEFI + BIOS) with grub
3. Create ISO with xorriso
4. Add SSH to extracted rootfs before ISO creation

**Option 4** if you want to stay with bootc ecosystem:
1. Use Dakota OCI (has working bootc)
2. Layer KDE apps on top
3. bootc install-to-disk works out of box

## Files for Reference

- `/var/tmp/aurora-serial.log` — UEFI boot attempt output
- `bootable.raw` — Empty, failed bootc output
- `bootable-orig.raw` — Another failed attempt
- `rebuild-with-ssh.sh` — Automation for future use

## Bottom Line

The infrastructure is correct, the approach is correct, but:
1. Aurora OCI doesn't have bootc (DNS issues prevented adding it)
2. Trying to add SSH via Dockerfile corrupted the image
3. bootc install-to-disk requires bootc to be IN the image

**Next session should focus on:** ISO creation or using Dakota as base (both proven methods)
