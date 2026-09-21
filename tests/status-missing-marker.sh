#!/usr/bin/env bash
#
# Regression coverage for status.sh's missing / unrecognized PROJECT-STATUS marker guard.
#
# When overview.md exists but carries none of the three recognized markers (not-started, retcon,
# kickoff-complete) — a lost or corrupted marker — status.sh must NOT confidently resolve the index.
# Doing so would misreport "Run STEP-1.1", which is wrong for a pre-kickoff greenfield (should run
# kickoff) and for a mid-adoption retcon (should follow RETCON-PROMPT.md) alike. It must report an
# indeterminate result and route to the AGENTS.md "First action" decision, which restores the marker
# by ASKING the project's human — not by reading the answer off the project's own files. The
# recognized markers still route as before.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-status-marker-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

index="$TMP_ROOT/STEP-index.md"
overview="$TMP_ROOT/overview.md"

# A STEP-index with STEP-1 Planned and no implementation STEPs — the state a lost-marker project
# sits over, and the one that used to misresolve to "Run STEP-1.1".
{
  printf '# idx\n\n'
  printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
  printf '|------|-------|-------|--------|--------------------|------------------|\n'
  printf '| STEP-1 | Architecture | | Planned | | Architecture-first. |\n'
} > "$index"

run_status() {
  THROUGHSTONE_OVERVIEW="$overview" THROUGHSTONE_STEP_INDEX="$index" "$STATUS"
}

assert_contains() {
  local output="$1" expected="$2"
  printf '%s\n' "$output" | grep -Fq "$expected" || {
    printf 'FAIL: expected status output to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
}
refute_contains() {
  local output="$1" needle="$2"
  if printf '%s\n' "$output" | grep -Fq "$needle"; then
    printf 'FAIL: status output should NOT contain: %s\n' "$needle" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
}

# 1. Marker line stripped entirely — indeterminate, never a confident STEP-1.1.
printf '# Overview\n\n(the PROJECT-STATUS marker line has been lost)\n' > "$overview"
out="$(run_status)"
assert_contains "$out" "indeterminate"
assert_contains "$out" "no recognized PROJECT-STATUS marker"
assert_contains "$out" "RETCON-PROMPT.md"
refute_contains "$out" "Run STEP-1.1"
# The recovery is an ask, not an inference: the guard must send the agent to the person, and must
# not hand it a disk-shape rule to decide the mode with.
assert_contains "$out" "Ask whoever owns this project"
refute_contains "$out" "still-bare STEP-index seed"

# 2. Unrecognized marker value — same guard (not one of the three known values).
printf '# Overview\n\n<!-- PROJECT-STATUS: bogus -->\n' > "$overview"
out="$(run_status)"
assert_contains "$out" "indeterminate"
refute_contains "$out" "Run STEP-1.1"

# 3. Recognized markers still route as before (guard must not over-fire).
printf '# Overview\n\n<!-- PROJECT-STATUS: retcon -->\n' > "$overview"
assert_contains "$(run_status)" "marker: retcon"

printf '# Overview\n\n<!-- PROJECT-STATUS: not-started -->\n' > "$overview"
assert_contains "$(run_status)" "kickoff not started"

# kickoff-complete falls through to ordinary index resolution (bare seed -> start STEP-1).
printf '# Overview\n\n<!-- PROJECT-STATUS: kickoff-complete -->\n' > "$overview"
out="$(run_status)"
refute_contains "$out" "indeterminate"
assert_contains "$out" "Run STEP-1.1"

echo "status.sh missing-marker guard: PASS"
