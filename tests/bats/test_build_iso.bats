#!/usr/bin/env bats
# BATS tests for tromso/src/build-iso.sh

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  BUILD_ISO="${REPO_ROOT}/tromso/src/build-iso.sh"
}

@test "build-iso.sh: exists and is executable" {
  run test -x "${BUILD_ISO}"
  [ "$status" -eq 0 ]
}

@test "build-iso.sh: has bash shebang" {
  run head -1 "${BUILD_ISO}"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "build-iso.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${BUILD_ISO}"
  [ "$status" -eq 0 ]
}

@test "build-iso.sh: fails with usage when called with no arguments" {
  run bash "${BUILD_ISO}"
  [ "$status" -ne 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]]
}

@test "build-iso.sh: fails with usage when called with one argument" {
  run bash "${BUILD_ISO}" /tmp/boot.tar
  [ "$status" -ne 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]]
}

@test "build-iso.sh: fails with usage when called with two arguments" {
  run bash "${BUILD_ISO}" /tmp/boot.tar /tmp/squashfs.img
  [ "$status" -ne 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]]
}

@test "build-iso.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${BUILD_ISO}"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
