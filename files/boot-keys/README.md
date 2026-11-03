# Secure Boot keys

These helpers are inherited from GNOME/KDE Linux. The private keys in
`snakeoil/` are **public, development-only test fixtures**. Anyone can sign
with them. Never enrol their certificates on a machine you trust, or treat
an artifact signed by them as authentic. They are retained for disposable
local and CI development builds, following the upstream convention.

Tromso's current bootc pipeline does not invoke this Makefile and disables
Secure Boot signing in its boot elements. Published OCI images and ISO files
use cosign keyless signatures; those signatures do not establish a UEFI
Secure Boot chain. No production Secure Boot secret provisioning is currently
wired into these workflows.

## Modes and release guard

`make generate-keys` obtains keys according to `IMPORT_MODE`:

* Unset: generate fresh local keys.
* `snakeoil`: copy the committed public test keys; development only.
* `local`: copy the snakeoil PK/KEK/DB roots and generate other keys;
  development only, since the roots are still public.
* `import`: read keys and certificates from `SECURE_BOOT_*` environment
  variables. Every required variable must be nonempty; missing imports fail
  before writing outputs, even if previous outputs exist. No fallback occurs.

Any future release Secure Boot signing must use separately provisioned keys
with `IMPORT_MODE=import RELEASE_BUILD=1 make generate-keys`. Set these values
for the entire build, including scheduled releases. Do not print secrets with
`show-keys-for-ci` in CI logs.

`RELEASE_BUILD=1` checks inputs before generation and outputs afterwards.
It rejects both `snakeoil` and `local`, and compares all generated `.crt`
files (including bundles and extra firmware certificates) and environment
`SECURE_BOOT_*_CRT` values against every committed snakeoil certificate's
public key. This catches renamed, reformatted and reissued certificates.
Invalid certificates and unreadable reference certificates also fail closed.
Existing generated files are checked on every invocation; switching modes
does not make stale snakeoil files safe. Use a fresh working directory when
switching signing identities.

The publishing workflows run the same guard before building and before
publishing, for both OCI architectures and the live ISO, including nightlies:

```sh
python3 files/boot-keys/check-release-keys.py --release
```

No keys are required by this standalone check when Secure Boot signing is
unused. It checks signing inputs, not signatures embedded in downloaded or
cached artifacts, and does not claim to audit previously published images.
If signing is enabled later, provision private release keys in the signing
jobs, retain these checks, and audit the signed artifacts before publishing.

Other targets: `clean` deletes generated files; `export-snakeoil` replaces the
development fixtures and must never be used with production keys.

## Outputs

The Makefile will output the following keys:

* `PK`: Platform Key
* `KEK`: Key Enrollment key
* `DB`: Signature Database
* `VENDOR`: Vendor key for signing UEFI applications
* `MODULES`: Vendor key for signing kernel modules
* `SYSEXT`: Vendor key for signing system extensions

It will additionally output `-MIC` variants of the first two keys. These are
alternatives which include Microsoft keys in the chain of trust.

You can decide whether to enrol `PK` + `KEK` or `PK-MIC` + `KEK-MIC` in your
machine firmware.

The former option ensures that the firmware will ONLY boot software signed with
your chosen keys.

The latter option means the firmware will additionally allow any software
allowed by the Microsoft keys. This is useful if you want to allow the
machine to dual boot into other operating systems.
