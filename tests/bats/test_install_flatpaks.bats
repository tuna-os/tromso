#!/usr/bin/env bats
# BATS tests for tromso/src/install-flatpaks.sh
#
# This script requires network, dbus, and flatpak. Tests validate
# structure and shell syntax without running the full installation.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  INSTALL_FLATPAKS="${REPO_ROOT}/tromso/src/install-flatpaks.sh"
}

@test "install-flatpaks.sh: exists" {
  run test -f "${INSTALL_FLATPAKS}"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: has bash shebang" {
  run head -1 "${INSTALL_FLATPAKS}"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "install-flatpaks.sh: has set -exo pipefail" {
  run grep 'set -exo pipefail' "${INSTALL_FLATPAKS}"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: references FLATPAK_CACHE" {
  run grep 'FLATPAK_CACHE' "${INSTALL_FLATPAKS}"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: references flathub remote" {
  run grep 'flathub' "${INSTALL_FLATPAKS}"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${INSTALL_FLATPAKS}"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
