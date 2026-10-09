#!/usr/bin/env bats
# BATS tests for scripts/fisherman-install.sh
#
# This script is the e2e install gate: the plain and LUKS workflows fail only
# if it exits non-zero. Its exit code is therefore the thing worth testing, and
# it is testable without a disk — FISHERMAN_BIN is an env seam, so a stub
# stands in for the real installer and the script's own decisions (propagate,
# patch, skip) are exercised directly.
#
# The patch path itself needs a mounted deployment and root, so these tests
# cover the decisions reachable in a sandbox: a clean install must not fail the
# gate, a non-hostname failure must propagate fisherman's own code, and a
# hostname failure that cannot be patched must not report success.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/scripts/fisherman-install.sh"

  TMP="$(mktemp -d)"
  RECIPE="${TMP}/recipe.json"
  printf '{"hostname":"tromso-test","encryption":{"type":"none"}}\n' >"${RECIPE}"
}

teardown() {
  rm -rf "${TMP}"
}

# stub_fisherman writes a fake installer that prints $2 and exits $1.
stub_fisherman() {
  local rc="$1" output="$2"
  cat >"${TMP}/fisherman" <<EOF
#!/usr/bin/bash
cat <<'FISHLOG'
${output}
FISHLOG
exit ${rc}
EOF
  chmod +x "${TMP}/fisherman"
}

run_script() {
  run env FISHERMAN_BIN="${TMP}/fisherman" bash "${SCRIPT}" "${RECIPE}"
}

# stub_disk puts fake lsblk/mount/umount on PATH so the patch path can be
# driven to the point where it mounts a root and looks for the deployment's
# etc/ -- the case that used to report success after patching nothing. The
# mount is a no-op, so $MNT stays empty and no deployment tree is found.
stub_disk() {
  printf '#!/usr/bin/bash\necho "/dev/vda2 btrfs"\n' >"${TMP}/lsblk"
  printf '#!/usr/bin/bash\nexit 0\n' >"${TMP}/mount"
  printf '#!/usr/bin/bash\nexit 0\n' >"${TMP}/umount"
  chmod +x "${TMP}/lsblk" "${TMP}/mount" "${TMP}/umount"
}

run_script_with_disk() {
  run env PATH="${TMP}:${PATH}" FISHERMAN_BIN="${TMP}/fisherman" \
    bash "${SCRIPT}" "${RECIPE}"
}

@test "fisherman-install.sh: exists" {
  run test -f "${SCRIPT}"
  [ "$status" -eq 0 ]
}

@test "fisherman-install.sh: has bash shebang" {
  run head -1 "${SCRIPT}"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "fisherman-install.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${SCRIPT}"
  [ "$status" -eq 0 ]
}

@test "fisherman-install.sh: is valid bash" {
  run bash -n "${SCRIPT}"
  [ "$status" -eq 0 ]
}

# A successful install needs no patch, so the script must not touch the disk
# and must not fail the gate.
@test "fisherman-install.sh: succeeds and skips patching when fisherman succeeds" {
  stub_fisherman 0 "install complete"
  run_script
  [ "$status" -eq 0 ]
  [[ "$output" =~ "no post-install patch required" ]]
}

# A failure that is not the known hostname bug must surface as fisherman's own
# exit code -- the wrapper has no workaround for it and must not mask it.
@test "fisherman-install.sh: propagates a non-hostname failure with fisherman's exit code" {
  stub_fisherman 7 "error: no space left on device"
  run_script
  [ "$status" -eq 7 ]
  [[ "$output" =~ "non-hostname reason" ]]
}

# The regression this file exists for: fisherman failed, the wrapper is the
# only thing that writes the hostname, and it could not. Reporting success
# there makes CI pass for a system the installer never finished.
@test "fisherman-install.sh: fails when the hostname patch cannot be applied" {
  stub_fisherman 1 "error writing hostname: ostree admin --print-current-dir failed"
  run_script
  [ "$status" -ne 0 ]
  [[ "$output" =~ "post-install patch FAILED" ]]
}

@test "fisherman-install.sh: reports the reason the patch could not be applied" {
  stub_fisherman 1 "error writing hostname: ostree admin --print-current-dir failed"
  run_script
  # No /dev/vda in the test sandbox, so the device scan is what fails.
  [[ "$output" =~ "post-install patch not applied" ]]
}

# "complete" is the success marker; it must never be printed on a failure.
@test "fisherman-install.sh: does not claim completion when a patch failed" {
  stub_fisherman 1 "error writing hostname: ostree admin --print-current-dir failed"
  run_script
  [[ ! "$output" =~ "post-install patch complete" ]]
}

# The precise regression: fisherman failed, the root mounted fine, but the
# deployment's etc/ was never found -- so the hostname was never written. This
# path used to print "post-install patch complete" and exit 0, passing the
# gate for an install that did not finish.
@test "fisherman-install.sh: fails when the deployment etc/ is not found" {
  stub_fisherman 1 "error writing hostname: ostree admin --print-current-dir failed"
  stub_disk
  run_script_with_disk
  [ "$status" -ne 0 ]
  [[ "$output" =~ "deployment etc/ not found" ]]
  [[ ! "$output" =~ "post-install patch complete" ]]
}

# tromso is built from freedesktop-sdk; rechunker-group-fix.service is a
# Universal Blue unit it has never shipped. The override was inherited from
# dakota and wrote a drop-in for a service that does not exist.
@test "fisherman-install.sh: does not write the Universal Blue rechunker override" {
  run grep -c 'rechunker-group-fix' "${SCRIPT}"
  [ "$output" -eq 0 ]
}

@test "fisherman-install.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck --severity=error "${SCRIPT}"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
