# Experiment: tine vs utah (projectbluefin/utah) on utah's package set

Branch: `exp/tine-utah-race`. Workflow: `tine-utah-race.yml`. Rule:
`//tine-poc:utah-race-rootfs` (228 packages).

## Question

Utah builds bootc OCI images from a Containerfile on GitHub runners. Would
switching its image assembly to tine make it dramatically faster?

## Method

Same package NAMES as utah's `packages/utah.toml` + `packages/bluefin.toml`
(207 names), minus 2 absent from tine's Fedora catalog
(`linux-atm-libs`, `pipewire-libs-extra`), plus 26 boot-critical packages
utah inherits from its Hummingbird bootc-os base (kernel, dracut, ostree,
bootc, gdm, NetworkManager, ...). Full derivation:
`tine-poc/gen-utah-race-pkgs.py` → `tine-poc/utah_race_pkgs.bzl`.

Raced on `ubuntu-24.04` GitHub runners: tine `buck build` wall time vs
utah's `Build Image` container step (base pull + dnf + lint).

## Results

Two green tine runs on `ubuntu-24.04` (cold Buck cache), 2026-10-08:

| side | build time | shipped bytes |
|---|---|---|
| tine utah-race-rootfs (run 37773622251) | 268 s | tar 5,215,907,840 (~4.86 GiB); OCI dir 2,311,844,593 |
| tine utah-race-rootfs (run 37778343470) | 269 s | tar identical (byte-for-byte); `ghcr.io/tuna-os/tine-utah:race-9b42f034` |
| utah Containerfile Build Image step, warm registry cache (run 37696648076) | 156 s | published testing size: unknown (quay needs auth; recorded UNKNOWN, don't quote) |
| utah Containerfile Build Image step, cold (run 37737888033) | 318 s | — |

So: tine-cold (268s) ≈ utah-cold (318s) minus ~15%; utah-warm (156s)
beats tine-cold by ~40%. Tine with a warm Buck cache is unmeasured and
should win on rebuilds (only changed RPMs re-fetch) — upside, unproven,
and it would need cache infrastructure utah gets free from the registry.

## Fidelity caveats (read before quoting numbers)

- Same NAMES, not same versions/distro: utah ships factory-built GNOME 51
  on Hummingbird; tine resolves from Fedora rawhide (F46).
- tine build omits utah's contract verifications, branding scripts,
  gnome-extensions build, uupd, v4l2loopback/akmods kernel work, vuln scan.
- utah's step includes base-image pull + `bootc container lint`; tine's
  includes RPM fetch with a cold Buck cache. Lint is SKIPPED on both tine
  sides (no bootc on ubuntu-24.04 runners) — see open question re lint.

## Pros of tine for a utah-shaped build (observed)

- No per-layer rootfs walks: utah's own Containerfile comments that
  committing a layer costs ~10s pre-transaction / ~40s post-transaction on
  hosted runners; tine assembles one tar, no layer commits. This is where
  tine's ~50s cold-vs-cold edge plausibly comes from.
- Content-hash caching: repeat builds with a warm Buck cache should beat
  registry layer caching (only changed RPMs re-fetch); the 268s number is
  the cold-cache worst case. Unmeasured — needs cache infra to prove.
- Hermetic pinned snapshot catalog vs mutable repos + HUMMINGBIRD_REPO_DAY
  cache-busting dance. Real but operational, not speed.
- Deterministic: two runs produced byte-identical 5,215,907,840-byte tars.

## Cons of tine for a utah-shaped build (observed)

- No dramatic speedup: 268s vs 156–318s is noise, not a migration reason.
  The tromso 68x came from eliminating source compilation; utah never
  compiles in-image, so there is nothing to eliminate.
- No OCI output: utah's deliverable IS a signed bootc OCI image. The
  tar→buildah shim works for experiments but is not a release pipeline
  (no rechunk, no cosign, no OCI layout provenance).
- Custom repos need catalog tooling: utah's pinned utah-packages factory
  repo and Hummingbird repos have no tine-catalog equivalent; porting them
  means building snapshot infrastructure, not just a package list.
- RUN-time logic doesn't port: akmods/v4l2loopback kernel module builds,
  bootc lint, secureboot checks, contract verifications are imperative
  build steps with no declarative tine rule.
- Version skew: tine follows Fedora rawhide; utah pins factory GNOME 51.
  Tracking a non-Fedora package set in tine means owning a custom catalog.
- Ecosystem fork: utah shares the Bluefin/Universal-Blue Containerfile
  toolchain; a tine port is a maintained fork.

## Boot test: BLOCKED (cluster infra, not the image)

`tine-utah:race-c7cf2af1` pushed fine, but `corral bootc create` failed
4x and no VM ever booted:

1. First 2 attempts: default `--disk 80Gi` exceeds KubeVirt node staging
   space (~51Gi free) — SyncFailed, builder never started. Fixed with
   `--disk 30Gi` (matches utah-test).
2. Next attempts: builder's `bootc install to-disk` dies with
   `write /var/tmp/container_images_*: no space left on device` while
   pulling the 5.2GB image into the composefs repo. tine-kde (~2.5GB)
   fit; tine-utah does not — consistent with the builder scratch mount
   not absorbing the load (plugin 0.2.0), everything landing on the ~4G
   containerdisk root.
3. Side finding: plugin 0.2.0 probed `BACKEND=composefs ... FS=ext4`
   despite the image shipping bootupd (should be ostree/xfs). The
   checkout's probe checks bootupctl first; the installed plugin
   apparently doesn't. Worth a corral issue, not worked here.

No further attempts: each cycle burns ~10 min for zero new information,
and the verdict below doesn't need the boot (tine+shim bootability is
already proven by tine-kde; the race question is speed).

## Verdict

**Utah should NOT switch to tine.** Same-work assembly (binary RPMs in,
rootfs out) runs in the same band on both: tine-cold 268–269s vs utah
156s warm / 318s cold. The gain ceiling (~15% of one pipeline step that
is itself a fraction of kernel+E2E time) does not cover losing OCI-native
output, the factory-repo catalog gap, and the Bluefin toolchain fork.

**Proper OCI support in tine: not recommended on this evidence.** It only
pays if a tine-based product needs to ship bootc images routinely; right
now tine's value here is tromso DDI experiments, where tar output is
exactly what's wanted. Revisit if tine ever fronts a shippable image.
