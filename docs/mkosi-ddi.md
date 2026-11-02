# Local Mkosi DDI experiment

Tromsø has a local Mkosi experiment. It creates a GPT disk image from the
BuildStream root tree:

```sh
just build-mkosi-ddi
```

The configuration lives in `mkosi/ddi/`. Mkosi writes the raw image to
`output/mkosi-ddi/tromso-mkosi-ddi.raw`. It uses `Distribution=buildstream`
with one package, `elements/mkosi/tromso-ddi.bst`. This compose target uses
Tromsø's KDE runtime and `os-release` identity.

The DDI output is separate from `bootable.raw`, the OCI image and ISO files.
Mkosi creates a tools tree from Ubuntu `stonking` with BuildStream and its
Python plugins. The host needs Mkosi's system dependencies and access to
the project sources and cache.

## Not currently bootable

This local artifact contains a root tree, **not a bootable image** or a bootc
deployment. The GPT layout reserves 512 MiB for the ESP and an ext4 root for
x86-64. These partitions alone do not provide a boot chain.

The available initramfs, `elements/oci/initramfs.bst`, uses `INITRD_MODE=oci`.
Tromsø's root tree contains OSTree/bootc integration: `ostree` points into
`/sysroot/ostree`. This Mkosi path only checks out a filesystem tree.
It does not create an OSTree deployment or run `bootc install`.

No local element provides a tested initramfs and command line for this direct
ext4 root. The DDI therefore has no `Bootable=yes`, boot loader, or root
kernel arguments. Do not boot or distribute it as an OS image.

A bootable output needs a supported contract for a non-OSTree root.
It needs an initramfs, a command line that finds and mounts that root, and
evidence of a successful boot. This experiment has no release or publication
path. It does not change the bootc, OCI, ISO or publication recipes.
