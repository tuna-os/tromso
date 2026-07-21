kind: script
description: Orchestrated OSTree repository with ORPHANED commit for bootc

build-depends:
  - freedesktop-sdk.bst:vm/prepare-image.bst
  - freedesktop-sdk.bst:components/ostree.bst
  - filename: oci/kde-linux/filesystem.bst
    config:
      location: /sysroot

variables:
  uuidnamespace: aea54278-2587-4075-ae67-8688ace4ce3d

config:
  commands:
  - |
    # 1. Clean up
    find /sysroot/lib/modules/ -name "*.json" -delete
    
    # 2. Setup kernel version
    version=$(ls -1 /sysroot/lib/modules | grep -E '^[0-9]' | head -n1)
    mkdir -p "/sysroot/usr/lib/modules/${version}"
    cp /sysroot/boot/vmlinuz "/sysroot/usr/lib/modules/${version}/vmlinuz"
    
    # 3. Add markers
    mkdir -p /sysroot/usr/lib/ostree
    echo -e "[composefs]\nenabled = yes" > /sysroot/usr/lib/ostree/prepare-root.conf
    
    mkdir -p /sysroot/usr/lib/bootc/kargs.d
    echo "rw console=tty0 console=ttyS0" > /sysroot/usr/lib/bootc/kargs.d/00-aurora.kargs
    
    mkdir -p /sysroot/usr/lib/bootc/install
    echo -e "[install]\nroot-fs-type = xfs" > /sysroot/usr/lib/bootc/install/00-aurora.conf

    # 4. Standard prepare-image
    prepare-image.sh        --sysroot /sysroot        --seed "%{uuidnamespace}"        --rootpasswd root        --rootsource LABEL=root        --efisource LABEL=EFI        --efipath /boot >/dev/null

    # 5. Guaranteed purge of /boot
    rm -rf /sysroot/boot/*
    mv /sysroot/etc /sysroot/usr/etc

  - |
    version=$(ls -1 /sysroot/usr/lib/modules | grep -E '^[0-9]' | head -n1)
    mkdir barerepo
    ostree init --repo=barerepo
    # THE CRITICAL FIX: --parent=none
    ostree commit       --repo=barerepo       --consume /sysroot       --branch="aurora/x86_64/latest"       --parent=none       --timestamp="2011-11-11 11:11:11+00:00"       --add-metadata-string="ostree.linux=/usr/lib/modules/${version}/vmlinuz"       --add-metadata-string="ostree.initramfs=/usr/lib/modules/${version}/initramfs.img"       --add-metadata-string="ostree.architecture=x86_64"

    ostree init --repo="%{install-root}" --mode=archive
    ostree pull-local --repo="%{install-root}" barerepo "aurora/x86_64/latest"
