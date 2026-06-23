#!/usr/bin/env bats
# BATS tests for Claude/Gemini skill scripts
#
# These are AI agent assistance scripts used during development.
# Tests validate existence, shebang, set flags, usage, and shellcheck.

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

# ═══════════════════════════════════════════════════════════════════════════
# .claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh
# ═══════════════════════════════════════════════════════════════════════════

@test "fetch_pkgbuild.sh: exists" {
  run test -f "${REPO_ROOT}/.claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh"
  [ "$status" -eq 0 ]
}

@test "fetch_pkgbuild.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/.claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh"
  [[ "$output" =~ ^#!/.*bash ]]
}

@test "fetch_pkgbuild.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/.claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh"
  [ "$status" -eq 0 ]
}

@test "fetch_pkgbuild.sh: fails when called with no arguments" {
  run bash "${REPO_ROOT}/.claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ required ]]
}

@test "fetch_pkgbuild.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/.claude/skills/arch-pkgbuild/scripts/fetch_pkgbuild.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# .claude/skills/bst-lint/scripts/lint_bst.sh
# ═══════════════════════════════════════════════════════════════════════════

@test "lint_bst.sh: exists" {
  run test -f "${REPO_ROOT}/.claude/skills/bst-lint/scripts/lint_bst.sh"
  [ "$status" -eq 0 ]
}

@test "lint_bst.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/.claude/skills/bst-lint/scripts/lint_bst.sh"
  [[ "$output" =~ ^#!/.*bash ]]
}

@test "lint_bst.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/.claude/skills/bst-lint/scripts/lint_bst.sh"
  [ "$status" -eq 0 ]
}

@test "lint_bst.sh: prints usage when called with no arguments" {
  run bash "${REPO_ROOT}/.claude/skills/bst-lint/scripts/lint_bst.sh"
  [ "$status" -ne 0 ]
}

@test "lint_bst.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/.claude/skills/bst-lint/scripts/lint_bst.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# .claude/skills/build-log-extract/scripts/extract_error.sh
# ═══════════════════════════════════════════════════════════════════════════

@test "extract_error.sh: exists" {
  run test -f "${REPO_ROOT}/.claude/skills/build-log-extract/scripts/extract_error.sh"
  [ "$status" -eq 0 ]
}

@test "extract_error.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/.claude/skills/build-log-extract/scripts/extract_error.sh"
  [[ "$output" =~ ^#!/.*bash ]]
}

@test "extract_error.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/.claude/skills/build-log-extract/scripts/extract_error.sh"
  [ "$status" -eq 0 ]
}

@test "extract_error.sh: prints usage when called with no arguments" {
  run bash "${REPO_ROOT}/.claude/skills/build-log-extract/scripts/extract_error.sh"
  [ "$status" -ne 0 ]
}

@test "extract_error.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/.claude/skills/build-log-extract/scripts/extract_error.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# .claude/skills/bump-package-source/scripts/bump_source.sh
# ═══════════════════════════════════════════════════════════════════════════

@test "bump_source.sh: exists" {
  run test -f "${REPO_ROOT}/.claude/skills/bump-package-source/scripts/bump_source.sh"
  [ "$status" -eq 0 ]
}

@test "bump_source.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/.claude/skills/bump-package-source/scripts/bump_source.sh"
  [[ "$output" =~ ^#!/.*bash ]]
}

@test "bump_source.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/.claude/skills/bump-package-source/scripts/bump_source.sh"
  [ "$status" -eq 0 ]
}

@test "bump_source.sh: prints usage when called with no arguments" {
  run bash "${REPO_ROOT}/.claude/skills/bump-package-source/scripts/bump_source.sh"
  [ "$status" -ne 0 ]
}

@test "bump_source.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/.claude/skills/bump-package-source/scripts/bump_source.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# .claude/skills/kde-linux-ref/scripts/fetch_kde_linux_ref.sh
# ═══════════════════════════════════════════════════════════════════════════

@test "fetch_kde_linux_ref.sh: exists" {
  run test -f "${REPO_ROOT}/.claude/skills/kde-linux-ref/scripts/fetch_kde_linux_ref.sh"
  [ "$status" -eq 0 ]
}

@test "fetch_kde_linux_ref.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/.claude/skills/kde-linux-ref/scripts/fetch_kde_linux_ref.sh"
  [[ "$output" =~ ^#!/.*bash ]]
}

@test "fetch_kde_linux_ref.sh: has set flags" {
  run grep 'set -e' "${REPO_ROOT}/.claude/skills/kde-linux-ref/scripts/fetch_kde_linux_ref.sh"
  [ "$status" -eq 0 ]
}

@test "fetch_kde_linux_ref.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/.claude/skills/kde-linux-ref/scripts/fetch_kde_linux_ref.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
