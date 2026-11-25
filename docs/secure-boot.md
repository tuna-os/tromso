# Secure Boot

Issue: [#516](https://github.com/tuna-os/tromso/issues/516). Policy:
[tuna-os/tunaOS#4955](https://github.com/tuna-os/tunaOS/issues/4955). The
full design, with sources, is `installer-medium/docs/SECURE-BOOT.md` in
tuna-os/tunaOS.

This page tells you what the publish job signs, what it does not sign, and
what no test has shown yet.

## The chain

Tromsø is a `tunaos-key` image. The boot chain is:

1. The firmware starts shim. Microsoft signed that shim for Fedora.
2. shim starts systemd-boot. The file name is `grubx64.efi`, because shim
   looks for that name. The tunaOS key signed it.
3. systemd-boot starts the kernel. shim checks the kernel against the tunaOS
   certificate.

A PC does not know the tunaOS certificate. The owner of the PC adds it one
time, in MokManager, from the file `tunaos-secure-boot.cer` on the ESP. A
virtual machine with no keys gets the key bundle from systemd-boot with no
prompt.

## What the publish job does

BuildStream does not sign. BuildStream keeps each source in its cache, and
CI publishes that cache to GHCR. A key in the build becomes public.

So `build-final.yml` adds the signed files as one layer. The steps run after
the build and before the push, only on `main` and `stable`, only for x86_64:

1. Check out `installer-medium/secure-boot` of tuna-os/tunaOS at a pinned
   commit.
2. Run `image/sign-image.sh`. This is the only step that gets
   `TUNAOS_SB_KEY` and `TUNAOS_SB_CERT`.
3. Run `image/verify-image.sh`. This step has no key. It uses `sbverify`
   with the certificate from the tunaOS repository.

A publish run with no key fails. The push, the cosign signature and the
promotion use the digest that has the layer.

The layer holds these files:

| File | Content |
|---|---|
| `/usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed` | systemd-boot with the tunaOS signature |
| `/usr/lib/systemd/boot/efi/systemd-bootx64.efi` | systemd-boot with no signature |
| `/usr/lib/modules/<version>/vmlinuz` | the kernel with the tunaOS signature |
| `/usr/lib/tunaos/secure-boot/shimx64.efi`, `mmx64.efi` | the Fedora shim and MokManager |
| `/usr/lib/tunaos/secure-boot/tunaos-secure-boot.cer` | the public certificate |
| `/usr/lib/tunaos/secure-boot/keys/auto/` | the key bundle for systemd-boot |
| `/usr/lib/tunaos/secure-boot/mode` | the text `tunaos-key` |
| `/usr/lib/tunaos/secure-boot/provenance.toml` | the pin of the shim |
| `/usr/bin/tuna-secure-boot` | the helper for the installer |

## The shim

tunaOS builds no shim. The layer holds `shim-x64-16.1-7` from Fedora, byte
for byte. Dakota uses the same file. The pin is `image/shim.toml` in the
tunaOS repository: the Koji URL, the sha256, the source package and the
licence (BSD-3-Clause). The upstream is `rhboot/shim`.

## What has no signature

Be exact about the limits.

- **The initramfs and the kernel command line.** The image has no UKI. The
  boot entry names a kernel, an initramfs and a command line. Only the
  kernel has a signature. The command line holds the composefs digest of
  the root. A person who can write to the ESP can change the initramfs or
  the digest. Secure Boot does not stop that.
- **Kernel modules.** They have no signature. The kernel does not enforce
  module signatures.
- **The aarch64 image.** It has no layer.
- **The live ISO.** `tromso/src/build-iso.sh` copies the systemd-boot with
  no signature. The ISO boots with Secure Boot off, as before.
- **The installed ESP.** bootc copies the signed systemd-boot only. A
  system from the old installer has no shim on its ESP. It boots with
  Secure Boot off, or with the tunaOS key in the firmware. The new
  installer daemon must copy shim (tuna-os/fisherman#521).

## Who can use the key

The key is the secret `TUNAOS_SB_KEY`. The certificate is the secret
`TUNAOS_SB_CERT`. One step of the publish job gets them. A pull request from
a fork gets no secret.

### The target

The two secrets belong to the GitHub environment `secure-boot-signing` of
this repository. GitHub gives an environment secret only to a job that names
the environment. The branch policy of the environment admits `main`
only, and GitHub rejects a job that names the environment on any
other branch. A workflow on a branch thus cannot read the key.

The `build_final` job in `build-final.yml` names the environment on `main`
and `stable`. On any other ref the name is empty, so a branch dispatch still
builds, with no environment and no key.
`tests/pytest/test_secure_boot_environment.py` fails if a workflow reads the
two secrets in any other job.

### The state on 2026-11-25

- The environment exists in tuna-os/tunaOS, tuna-os/tromso and
  tuna-os/brussels, with the branch policy `main`.
- The environment holds no secret yet. `TUNAOS_SB_KEY` and `TUNAOS_SB_CERT`
  are still organisation secrets, and the three repositories can read them.
  The publish job gets them through the caller workflow.
- A person with write access can still add a workflow on a branch. That
  workflow can read the key until the owner moves it.

### What the owner must do

GitHub does not give a secret back, so only a person who has the key file
can move it. The owner runs `tunaos-secure-boot-lockdown.sh` with the key
file from the backup. For each of the three repositories the script sets
the two secrets in the environment. Then it deletes the two organisation
secrets. After that step:

- Remove the two `TUNAOS_SB_*` lines under `secrets:` in
  `build-tromso-multirunner.yml`, and the two entries under
  `workflow_call.secrets` in `build-final.yml`. They pass nothing then.
- Make sure the next publish run on `main` passes the step
  `Add the Secure Boot layer`.

### The limits that stay

- The workflow still names the environment on `stable`, and the
  environment does not admit that branch. GitHub thus rejects `build_final`
  there. No workflow starts a build on `stable`: `promote-stable.yml` copies
  the tested digest. Do not admit `stable` again. No ruleset protects that
  name, so a person with write access could create it and sign from it.
- The environment has no required reviewers. A change that merges to `main`
  can use the key with no second approval.
- The same key signs systemd-boot and the kernel. On a machine that gets
  the key bundle, that key is also the platform key. The key has no offline
  root.

## What a test has shown

| Claim | State |
|---|---|
| `sign-image.sh` and `verify-image.sh` work on the published Tromsø image | Shown with a throwaway key, on a local machine. `bootc container lint` gives the same result before and after. See tuna-os/tunaOS#4963. |
| The publish job signs with the real key | Not shown. The nightly build must pass first. |
| The image boots with Secure Boot on | Not shown. |
| MokManager accepts the certificate on a PC | Not shown. |

`files/boot-keys/` is a different thing. It holds the old key Makefile from
the GNOME OS recipe. The image does not use it, and
`check-release-keys.py` still rejects its test keys.
