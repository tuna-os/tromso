#!/usr/bin/env bats
# BATS tests for tromso/src/configure-live.sh
#
# This script is designed to run inside a container. Tests validate
# structure and syntax without running the full live configuration.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  CONFIGURE_LIVE="${REPO_ROOT}/tromso/src/configure-live.sh"
}

@test "configure-live.sh: exists" {
  run test -f "${CONFIGURE_LIVE}"
  [ "$status" -eq 0 ]
}

@test "configure-live.sh: has bash shebang" {
  run head -1 "${CONFIGURE_LIVE}"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "configure-live.sh: has set -exo pipefail" {
  run grep 'set -exo pipefail' "${CONFIGURE_LIVE}"
  [ "$status" -eq 0 ]
}

@test "configure-live.sh: defines SCRIPT_DIR" {
  run grep 'SCRIPT_DIR=' "${CONFIGURE_LIVE}"
  [ "$status" -eq 0 ]
}

@test "configure-live.sh: references liveuser" {
  run grep 'liveuser' "${CONFIGURE_LIVE}"
  [ "$status" -eq 0 ]
}

@test "configure-live.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${CONFIGURE_LIVE}"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
