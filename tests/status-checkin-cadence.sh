#!/usr/bin/env bash
#
# Regression coverage for the project-selectable check-in cadence in status.sh.
#
# The cadence target N is read from overview.md's `<!-- CHECK-IN-CADENCE: N -->` marker
# (default 20 when absent or malformed). status.sh flags a heads-up (DUE) at N-5 and OVERDUE
# at N+5. This exercises those boundaries for a few N and the default/fallback paths.
#
# It also holds METHOD.md §10 rule 7's contract: the cadence advises and proposes, and never
# becomes the next action. An overdue project must still be told to get on with its next STEP —
# the case at the end asserts both halves, because a gate would satisfy every cadence assertion
# above while breaking the rule they exist to serve.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-cadence-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

OVERVIEW="$TMP_ROOT/overview.md"
INDEX="$TMP_ROOT/STEP-index.md"

# write_overview LINE — seed a minimal overview.md; LINE is the CHECK-IN-CADENCE marker to
# include (pass an empty string to omit it and exercise the default).
write_overview() {
  {
    printf '# Fixture — Project Overview\n\n'
    [ -n "$1" ] && printf '%s\n' "$1"
    printf '<!-- PROJECT-STATUS: kickoff-complete -->\n'
  } > "$OVERVIEW"
}

# write_index SINCE — a STEP table with a Check-in at STEP-1 and a later STEP SINCE steps on,
# so status.sh computes `since == SINCE`.
write_index() {
  local maxstep=$(( 1 + $1 ))
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    printf '| STEP-1 | Check-in | | Done | | Fixture |\n'
    printf '| STEP-%d | Later work | | Done | | Fixture |\n' "$maxstep"
  } > "$INDEX"
}

# run_cadence CADENCE_LINE SINCE — point status.sh at the fixtures and return its output.
run_cadence() {
  write_overview "$1"
  write_index "$2"
  THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS"
}

# assert_contains OUTPUT EXPECTED — the relevant cadence sentence is present.
assert_contains() {
  if ! printf '%s\n' "$1" | grep -Fq "$2"; then
    printf 'FAIL: expected status output to contain: %s\n' "$2" >&2
    printf '%s\n' "$1" >&2
    return 1
  fi
}

# --- Default cadence (no marker → N=20): DUE at 15, OVERDUE at 25 --------------
assert_contains "$(run_cadence '' 14)" 'STEPs of headroom.'
assert_contains "$(run_cadence '' 15)" "DUE (you're in the 15–24 window)."
assert_contains "$(run_cadence '' 24)" "DUE (you're in the 15–24 window)."
assert_contains "$(run_cadence '' 25)" 'OVERDUE (25+).'

# --- Explicit N=50: DUE at 45, OVERDUE at 55 ----------------------------------
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 50 -->' 44)" 'STEPs of headroom.'
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 50 -->' 45)" "DUE (you're in the 45–54 window)."
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 50 -->' 55)" 'OVERDUE (55+).'

# --- Explicit N=15 reproduces the previous window: DUE at 10, OVERDUE at 20 ----
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 15 -->' 10)" "DUE (you're in the 10–19 window)."
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 15 -->' 20)" 'OVERDUE (20+).'

# --- A malformed marker falls back to the default N=20 ------------------------
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: nope -->' 15)" "DUE (you're in the 15–24 window)."
assert_contains "$(run_cadence '<!-- CHECK-IN-CADENCE: 0 -->' 15)" "DUE (you're in the 15–24 window)."

# --- The "no Check-in STEP yet" nudge honours N (gate at N-5) ------------------
write_overview ''
{
  printf '# Resolver fixture\n\n'
  printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
  printf '|------|-------|-------|--------|--------------------|------------------|\n'
  printf '| STEP-15 | Later work | | Done | | Fixture |\n'
} > "$INDEX"
output="$(THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS")"
assert_contains "$output" 'no Check-in STEP yet — consider one (15 STEPs in; cadence is ~15–25).'

# --- The cadence advises; it never becomes the next action (METHOD.md §10 rule 7) ----
# A badly overdue project with a Planned STEP still resolves to planning that STEP. The check-in
# is offered beside it, marked as advice. Rule 7 sits after rule 5 in §10 for this reason, and
# the wording is asserted so a future "insert a Check-in STEP" imperative cannot creep back in.
write_overview ''
{
  printf '# Resolver fixture\n\n'
  printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
  printf '|------|-------|-------|--------|--------------------|------------------|\n'
  printf '| STEP-1 | Check-in | | Done | | Fixture |\n'
  printf '| STEP-41 | Build the thing | | Planned | | Fixture |\n'
} > "$INDEX"
output="$(THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS")"
assert_contains "$output" 'OVERDUE (25+).'
assert_contains "$output" 'plan STEP-41'
assert_contains "$output" 'Also worth proposing: a Check-in STEP'
assert_contains "$output" 'Advice, not a gate'
if printf '%s\n' "$output" | grep -Fq 'insert a Check-in STEP now'; then
  printf 'FAIL: the cadence became an imperative; rule 7 must propose, not mandate\n' >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

# A project inside its headroom is not offered one at all.
write_index 5
output="$(THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS")"
if printf '%s\n' "$output" | grep -Fq 'Also worth proposing'; then
  printf 'FAIL: a project with headroom should not be offered a Check-in STEP\n' >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

echo "status.sh check-in cadence: PASS"
