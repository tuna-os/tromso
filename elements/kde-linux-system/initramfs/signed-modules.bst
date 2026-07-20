kind: manual
description: "Prepare kernel modules and vmlinuz for bootc (aligned with Dakota)"

build-depends:
- filename: freedesktop-sdk.bst:components/linux.bst
  strict: true
- freedesktop-sdk.bst:components/findutils.bst

config:
  install-commands:
  - |
    mkdir -p "%{install-root}%{indep-libdir}/modules"
    cp -rT /usr/lib/modules "%{install-root}%{indep-libdir}/modules"

  - |
    version="$(ls -1 /usr/lib/modules | head -n1)"
    mkdir -p "%{install-root}%{indep-libdir}/modules/${version}"
    cp /boot/vmlinuz "%{install-root}%{indep-libdir}/modules/${version}/vmlinuz"

  # Create the ostree-boot directory with both kernel and initrd
  - |
    mkdir -p "%{install-root}%{indep-libdir}/ostree-boot"
    version="$(ls -1 /usr/lib/modules | head -n1)"
    cp /boot/vmlinuz "%{install-root}%{indep-libdir}/ostree-boot/vmlinuz-${version}"
    # Note: initramfs.img is added later in oci/initramfs.bst, but we can't easily 
    # add it here without circular dependency. 
    # Instead, we will add it to ostree-boot in oci/initramfs.bst.

variables:
  strip-binaries: ''
