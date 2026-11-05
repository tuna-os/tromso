# Local Mkosi DDI experiment

Tromso has an isolated Mkosi configuration for experimenting with a GPT disk
image from the BuildStream root tree:

```sh
just build-mkosi-ddi
```

The configuration is under `mkosi/ddi/`; the raw image is written to
`output/mkosi-ddi/tromso-mkosi-ddi.raw`. It uses Mkosi's `Distribution=buildstream`
backend and exactly one package, the `elements/mkosi/tromso-ddi.bst` compose
target. That compose uses Tromso's KDE runtime stack and carries the established
Tromso `os-release` identity. The raw DDI is separate from `bootable.raw`, the
OCI image, and ISO outputs. The Mkosi tools tree is generated from Ubuntu
`stonking` and includes BuildStream and its Python plugins, so the host only
needs Mkosi's system dependencies and access to the BuildStream project
sources/cache.

## Not currently bootable

This output is a local root-tree disk artifact, **not a bootable image** and not
a bootc deployment. The explicit GPT layout reserves a 512 MiB EFI System
Partition and an ext4 x86-64 root partition, but defining partitions alone does
not establish a working boot chain.

The available Tromso initramfs is `elements/oci/initramfs.bst`, built with
`INITRD_MODE=oci`. Tromso's root tree also carries OSTree/bootc integration
(`ostree` points into `/sysroot/ostree`), while this Mkosi build only checks out
a BuildStream filesystem tree: it does not create an OSTree deployment in that
sysroot or run `bootc install`. No local element supplies a tested initramfs
and kernel command-line contract for mounting this direct ext4 root as the
running system. Therefore this DDI deliberately has no `Bootable=yes`, boot
loader, or root kernel-argument configuration. Do not boot or distribute it as
a working OS image.

Making it bootable requires a Tromso-supported direct-root boot contract: an
initramfs suitable for a non-OSTree root, a defined root-device discovery / root
mount command line, and evidence that the composed tree can boot with those
artifacts. This is an experimental local output only; it adds no CI, release,
push, signing, or publication path and does not alter the existing bootc
`generate-bootable-image`, OCI, ISO, or publication recipes.
