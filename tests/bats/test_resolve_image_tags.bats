#!/usr/bin/env bats
# BATS tests for scripts/resolve-image-tags.sh

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  RESOLVE_TAGS="${REPO_ROOT}/scripts/resolve-image-tags.sh"
}

@test "resolve-image-tags.sh: exists and is executable" {
  [ -f "${RESOLVE_TAGS}" ]
  [ -x "${RESOLVE_TAGS}" ]
}

@test "resolve-image-tags.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck --severity=error "${RESOLVE_TAGS}"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

@test "resolve-image-tags.sh: channel owner produces bare channel tags on main" {
  run "${RESOLVE_TAGS}" --ref refs/heads/main --sha testsha123 --channel-owner true --date 20261024
  [ "$status" -eq 0 ]
  [ "$output" = "latest nightly nightly-20261024 testsha123" ]
}

@test "resolve-image-tags.sh: channel owner produces bare channel tags on stable" {
  run "${RESOLVE_TAGS}" --ref refs/heads/stable --sha testsha123 --channel-owner true --date 20261024
  [ "$status" -eq 0 ]
  [ "$output" = "stable stable-20261024 testsha123" ]
}

@test "resolve-image-tags.sh: non-channel-owner produces suffixed tags on main" {
  run "${RESOLVE_TAGS}" --ref refs/heads/main --sha testsha123 --channel-owner false --tag-suffix -aarch64 --date 20261024
  [ "$status" -eq 0 ]
  [ "$output" = "latest-aarch64 nightly-aarch64 nightly-20261024-aarch64 testsha123-aarch64" ]
}

@test "resolve-image-tags.sh: non-channel-owner produces suffixed tags on stable" {
  run "${RESOLVE_TAGS}" --ref refs/heads/stable --sha testsha123 --channel-owner false --tag-suffix -aarch64 --date 20261024
  [ "$status" -eq 0 ]
  [ "$output" = "stable-aarch64 stable-20261024-aarch64 testsha123-aarch64" ]
}

@test "resolve-image-tags.sh: non-channel-owner rejects empty tag suffix" {
  run "${RESOLVE_TAGS}" --ref refs/heads/main --sha testsha123 --channel-owner false --tag-suffix ""
  [ "$status" -ne 0 ]
  [[ "$output" =~ "non-channel-owner must specify non-empty tag suffix" ]]
}

@test "resolve-image-tags.sh: channel owner rejects tag suffix" {
  run "${RESOLVE_TAGS}" --ref refs/heads/main --sha testsha123 --channel-owner true --tag-suffix -foo
  [ "$status" -ne 0 ]
  [[ "$output" =~ "channel owner must not specify tag suffix" ]]
}
