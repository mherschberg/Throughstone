#!/usr/bin/env bash
#
# Regression coverage for conditional-session priority in status.sh, and for the per-title arms
# that answer for whichever STEP is In progress.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-status-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# write_index PATH ROWS — write the minimum STEP table the resolver needs.
write_index() {
  local path="$1" rows="$2"
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    printf '%s\n' "$rows"
  } > "$path"
}

# run_status INDEX — point status.sh at a fixture index without touching scaffold docs.
run_status() {
  local index="$1"
  THROUGHSTONE_STEP_INDEX="$index" "$STATUS"
}

# assert_contains OUTPUT EXPECTED — preserve the relevant resolver sentence while allowing the
# rest of the status report to evolve.
assert_contains() {
  local output="$1" expected="$2"
  if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
    printf 'FAIL: expected status output to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

# assert_absent OUTPUT UNEXPECTED — an arm that answers correctly while the wrong answer is still
# in the output is not fixed, so the displaced wording is asserted against directly.
assert_absent() {
  local output="$1" unexpected="$2"
  if printf '%s\n' "$output" | grep -Fq "$unexpected"; then
    printf 'FAIL: expected status output NOT to contain: %s\n' "$unexpected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

index="$TMP_ROOT/STEP-index.md"

# Planned conditional follow-ups beat ordinary planned implementation work, even when their
# STEP number is later.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |
| STEP-12 | Conditional session: AI feature | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Architecture follow-up required — STEP-12 (Conditional session: AI feature) is Planned.'

# A conditional session is one whose title starts with the phrase. A planned STEP that only
# mentions one is ordinary work, so the lowest-numbered planned STEP is still next.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |
| STEP-12 | Follow-up from Conditional session: AI feature | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Building — no STEP In progress; next up is STEP-2 (Ordinary implementation).'

# Active ordinary implementation remains the user's current work and takes precedence over a
# planned conditional follow-up. Its guidance is the ordinary substep guidance, read from its own
# title, even though the last row in the index is the conditional one.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | In progress | | Fixture |
| STEP-12 | Conditional session: AI feature | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Building — STEP-2 (Ordinary implementation) is In progress.'
assert_contains "$output" \
  'identify its lowest open substep'

# Active conditional work must emit by-name invocation guidance so agents do not run these
# thin follow-up prompts by STEP number.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |
| STEP-12 | Conditional session: AI feature | | In progress | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'identify its conditional template invocation BY NAME'

# The same rule on the active arm: an In-progress STEP that only mentions a conditional session
# gets the ordinary substep guidance, not the by-name invocation.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Follow-up from Conditional session: AI feature | | In progress | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'identify its lowest open substep'

# A Check-in STEP is the one STEP invoked whole (METHOD.md §10 rule 6): its two substeps are fixed
# and runbooks/check-in.md is their prompt, so nobody ever authors substep prompts for it. Without
# an arm of its own it takes the generic guidance and is told to wait for a command that will never
# be written, which is why both halves are asserted — the command it must wait for, and the one it
# must not be sent after.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-20 | Check-in: phase 1 | | In progress | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'wait for "run the check-in"'
assert_absent "$output" \
  'identify its lowest open substep'

# The scope after the title is optional (METHOD.md §5), so the bare row resolves the same way.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-20 | Check-in | | In progress | | Fixture |'
assert_contains "$(run_status "$index")" \
  'wait for "run the check-in"'

# The same rule the conditional arm keeps, for the same reason: the match is the documented row
# title, not the word. A project whose product is checking people in has STEPs of its own, and
# sending that feature work into the doc-drift runbook is worse than the generic answer.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-20 | Check-in flow | | In progress | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'identify its lowest open substep'
assert_absent "$output" \
  'run the check-in'

# With no conditional follow-up in the index, the resolver should select ordinary planned work.
write_index "$index" \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |'
output="$(run_status "$index")"
assert_contains "$output" \
  'Building — no STEP In progress; next up is STEP-2 (Ordinary implementation).'
assert_contains "$output" \
  'then stop for approval before running any substep'

echo "status.sh conditional priority + In-progress arms: PASS"
