# Aurora SSH Bootable Image — Current Status

**Session Date:** 2026-04-25  
**Goal:** Bootable VM and ISO with SSH support

## ✅ What's Complete

### Infrastructure Changes
- ✅ Added `openssh.bst` to `elements/aurora/deps.bst` (line 24)
- ✅ Added SSH enablement to `elements/oci/aurora.bst` (systemctl enable sshd)
- ✅ Removed problematic bootc BuildStream build from `elements/oci/layers/aurora-stack.bst`
- ✅ Removed old bootc injection code from Justfile

### Bootable Disk
- ✅ Created `/var/home/james/dev/kde-linux/bootable.raw` (30GB, bootc-created)
- ✅ Proper GPT partitions: BIOS boot (1M) + EFI (512M) + Linux root (29.5G)
- ✅ Copied to `/var/lib/libvirt/images/aurora-boot.qcow2` for libvirt testing
- ⚠️ **Note:** Current disk does NOT have SSH (built before openssh.bst added)

### Test Infrastructure
- ✅ `rebuild-with-ssh.sh` script ready (auto-builds, exports, creates new bootable disk with SSH)
- ✅ Auto-trigger script running (`/tmp/aurora-build-trigger.sh`)
- ✅ Justfile targets ready: `just build`, `just export`, `just generate-bootable-image`, `just boot-vm`

## ⏳ In Progress

**Current Build:** Still pushing artifacts to cache (slow, artifact size ~2.8GB)
- Waiting for: Pipeline Summary or build completion
- Auto-trigger will auto-run `rebuild-with-ssh.sh` when done

## 🚀 Your Options Now

### Option A: Wait for Auto-completion (Passive)
1. Build finishes automatically
2. `rebuild-with-ssh.sh` runs automatically
3. New bootable disk created with SSH support
4. **No action needed from you — just wait**

### Option B: Force Fresh Build Now (Active)
1. Kill current push: `pkill -f 'bst build'`
2. Run: `cd /var/home/james/dev/kde-linux && ./rebuild-with-ssh.sh`
3. Get SSH-enabled disk in ~10-15 minutes

### Option C: Test Current Disk First (Pragmatic)
1. Current disk works but has no SSH
2. Boot it and observe behavior: `just boot-vm`
3. Test via VNC or serial console
4. Add SSH in next iteration once you understand boot process

## 📝 Next Commands (When Ready)

### Start fresh SSH-enabled build:
```bash
cd /var/home/james/dev/kde-linux
./rebuild-with-ssh.sh
```

### Boot the result:
```bash
cd /var/home/james/dev/kde-linux
just boot-vm                    # Start QEMU with port forwarding
# In another terminal:
ssh -p 2222 root@127.0.0.1     # Connect via SSH (wait for boot to complete)
```

### Create ISO (separate task):
```bash
# TODO: ISO creation workflow (can use bootc or traditional live ISO)
```

## 📊 Build Timeline

- **~04:56 UTC:** Original build started (without openssh picked up)
- **~09:23 UTC:** Build still pushing (artifact 97d3691d)
- **Expected completion:** 10-15 more minutes
- **Then:** Fresh build with SSH = 5-15 minutes
- **Total estimate:** 20-30 minutes more

## 🔍 Verification

Check if SSH-enabled build completed:
```bash
grep "oci/aurora.bst" /var/tmp/aurora-build.log | grep -v "97d3691d"
```

Check auto-trigger status:
```bash
ps aux | grep aurora-build-trigger | grep -v grep
```

## 📍 File Locations

- Build log: `/var/tmp/aurora-build.log`
- Bootable disk: `/var/home/james/dev/kde-linux/bootable.raw`
- Rebuild script: `/var/home/james/dev/kde-linux/rebuild-with-ssh.sh`
- Auto-trigger: `/tmp/aurora-build-trigger.sh` (running)
- VM disk (libvirt): `/var/lib/libvirt/images/aurora-boot.qcow2`

---

**Recommendation:** Let auto-trigger complete (Option A). Check back in 20-30 minutes for SSH-enabled bootable disk ready to test.
