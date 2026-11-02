# Local Mkosi DDI experiment

Tromsø has a local Mkosi experiment. It targets a GPT disk image from the
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

The recipe uses `--include` to keep the project root as its current directory.
The BuildStream driver mounts both that directory and HOME. It does not rely
on a checkout under HOME for access to the project.

## Not currently bootable

This local artifact contains a root tree, **not a bootable image** or a bootc
deployment. The GPT layout reserves 512 MiB for the ESP and an ext4 root for
x86-64. These partitions alone do not provide a boot chain.

The available initramfs, `elements/oci/initramfs.bst`, uses `INITRD_MODE=oci`.
Tromsø's root tree contains OSTree/bootc integration: `ostree` points into
`/sysroot/ostree`. This Mkosi path only checks out a filesystem tree.
It does not create an OSTree deployment or run `bootc install`.

No local element provides a tested initramfs and command line for this direct
ext4 root. `Bootable=no` prevents automatic boot setup. This path does not
configure a boot loader or root kernel arguments. Do not boot or distribute
the artifact as an OS image.

A bootable output needs a supported contract for a non-OSTree root.
It needs an initramfs, a command line that finds and mounts that root, and
evidence of a successful boot. This experiment has no release or publication
path. It does not change the bootc, OCI, ISO or publication recipes.

## Exercised checks

We ran Mkosi `28~devel` from [upstream commit `9cf82a1`](https://github.com/systemd/mkosi/commit/9cf82a121c4afd3d64dc3b76c9db46f35bf7dd7c).
Its `summary` command resolved the project root, intended output directory, and
one BuildStream target. It reported bootability as disabled.
The pinned BuildStream container also resolved `mkosi/tromso-ddi.bst`.

These checks did not build the raw artifact. We did not boot a DDI.
