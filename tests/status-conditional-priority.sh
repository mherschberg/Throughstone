#!/usr/bin/env bash
#
# Regression coverage for late conditional-session priority in status.sh.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-status-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

write_index() {
  local path="$1" rows="$2"
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    printf '%s\n' "$rows"
  } > "$path"
}

run_status() {
  local index="$1"
  THROUGHSTONE_STEP_INDEX="$index" "$STATUS"
}

assert_contains() {
  local output="$1" expected="$2"
  if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
    printf 'FAIL: expected status output to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

index="$TMP_ROOT/STEP-index.md"

write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |
| STEP-12 | Conditional session: AI feature | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Architecture follow-up required — STEP-12 (Conditional session: AI feature) is Planned.'

write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | In progress | | Fixture |
| STEP-12 | Conditional session: AI feature | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Building — STEP-2 (Ordinary implementation) is In progress.'

write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |
| STEP-12 | Conditional session: AI feature | | In progress | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'invoke its conditional template BY NAME'

write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Building — no STEP In progress; next up is STEP-2 (Ordinary implementation).'

echo "status.sh conditional priority: PASS"
