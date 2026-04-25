# Aurora SSH Bootable Image — Current Build Status

**Session Date:** 2026-04-25  
**Time:** ~10:32 UTC  
**Goal:** Bootable VM and ISO with SSH support

## ✅ What's Complete

### Critical Fix Applied
- ✅ **Added kernel package (linux.bst)** to deps.bst
  - This was the root cause: Aurora image was missing vmlinuz
  - bootc install-to-disk couldn't create bootable disk without kernel files
  - Build will now include Linux kernel with initrd configuration
  
### Infrastructure Changes (Previous Session)
- ✅ Added `openssh.bst` to `elements/aurora/deps.bst`
- ✅ Added SSH enablement to `elements/oci/aurora.bst` (systemctl enable sshd)
- ✅ Removed problematic bootc BuildStream build from `elements/oci/layers/aurora-stack.bst`
- ✅ Git history preserved with commit ddbe38f

### Bootable Disk
- Previous attempts: bootable.raw exists (31GB) but unbootable
- Reason: Image was missing kernel, systemd, bootloader config
- Next step: Will regenerate with corrected build

## 🔨 In Progress

**Current Build:** Fresh build with kernel package
- Started: ~10:32 UTC
- Command: `bst build oci/aurora.bst`
- Expected duration: 20-30 minutes (core components build/fetch)
- Build log: `/var/tmp/aurora-build.log`

Build phases (sequential):
1. Resolve dependencies (checking cache for linux.bst, openssh.bst, etc.)
2. Fetch sources (Linux kernel source, openssh source)
3. Build base freedesktop-sdk components if needed
4. Build KDE application stack
5. Assemble OCI image with all layers
6. Export as OCI image (localhost/aurora:latest)

## 📋 After Build Completes

1. **Export to OCI image:**
   ```bash
   cd /var/home/james/dev/kde-linux
   just export
   ```

2. **Create bootable disk:**
   ```bash
   fallocate -l 30G bootable.raw
   LOOP=$(sudo losetup -f --show bootable.raw)
   sudo podman run --rm --privileged \
     -v /dev:/dev -v $(pwd):/data \
     --security-opt label=type:unconfined_t \
     localhost/aurora:latest \
     bootc install to-disk --wipe --filesystem ext4 /data/bootable.raw
   sudo losetup -d $LOOP
   ```

3. **Boot the VM:**
   ```bash
   just boot-vm
   # In another terminal:
   ssh -p 2222 root@127.0.0.1
   # (wait for boot to complete, typically 30-60 seconds)
   ```

## 🎯 Success Criteria

**Bootable VM:**
- ✓ QEMU boots with Aurora kernel
- ✓ Serial console shows systemd initialization
- ✓ SSH service starts and is accessible on port 2222
- ✓ `ssh root@127.0.0.1 -p 2222` connects successfully

**ISO Creation:**
- After VM boots successfully, create ISO for testing
- Can use `bootc` or traditional `xorriso` approach

## 📊 Expected Timeline

- **10:32 UTC** — Build starts with kernel package
- **10:50-11:00 UTC** — Build completes (28-30 min estimate)
- **11:00-11:05 UTC** — Export to OCI image
- **11:05-11:10 UTC** — Create bootable disk with bootc
- **11:10+** — Boot and test in QEMU

## 🔍 Verification Commands

Check build status:
```bash
tail -50 /var/tmp/aurora-build.log
pgrep -f "bst.*build oci/aurora" && echo "Build running" || echo "Build completed"
```

Check OCI image:
```bash
podman images localhost/aurora
podman inspect localhost/aurora:latest | grep -A 5 RootFS
```

## 📍 File Locations

- Build log: `/var/tmp/aurora-build.log`
- Git history: `git log --oneline | head -5` shows commit ddbe38f
- OCI image: `localhost/aurora:latest` (stored in podman storage)
- Bootable disk: `/var/home/james/dev/kde-linux/bootable.raw` (after generation)
- VM disk (libvirt): `/var/lib/libvirt/images/aurora-boot.qcow2`

---

**Note:** This is a fresh build with the critical kernel package added. Previous attempts failed because the image was missing vmlinuz files. This build should resolve that issue.
