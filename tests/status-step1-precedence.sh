#!/usr/bin/env bash
#
# Regression coverage for the STEP-1 row's authority over its own substeps in status.sh.
#
# METHOD.md §10 resolves the next action top-down and the first matching rule wins, with the
# index authoritative for which STEP is next. The substep rules sit near the top of that walk,
# so they have to be gated on the STEP-1 row: a STEP-1 marked Done over a still-open substep
# used to report "Architecture (STEP-1) in progress" and send the reader back into an
# architecture session, and — because that rule stops the walk — it kept reporting it for the
# rest of the project's life, hiding whatever STEP was actually in flight.
#
# The two directions of the same disagreement are both asserted here. The row wins in each:
# Done over an open substep means architecture is over, and an open row under substeps that are
# all final means the close-out is the work.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-step1-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

index="$TMP_ROOT/STEP-index.md"

# write_index STEP_ROWS SUB_ROWS — write the two tables the resolver reads. The substep table
# needs its own header: the parser locates each table's columns from the header it finds, so a
# substep row is only a substep row while a `Substep` header is in scope.
write_index() {
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    printf '%s\n\n' "$1"
    printf '| Substep | Session | Status | Output doc |\n'
    printf '|---------|---------|--------|------------|\n'
    printf '%s\n' "$2"
  } > "$index"
}

# run_status — point status.sh at the fixture index without touching scaffold docs.
run_status() {
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

# assert_absent OUTPUT UNEXPECTED — the routed-backwards answers are what this file exists to
# keep out, so they are asserted against directly rather than only implied by the right answer.
assert_absent() {
  local output="$1" unexpected="$2"
  if printf '%s\n' "$output" | grep -Fq "$unexpected"; then
    printf 'FAIL: expected status output NOT to contain: %s\n' "$unexpected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

open_substeps='| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Planned | architecture/07-data-model.md |'

# A STEP-1 row marked Done closes architecture even with sessions left open — the state an
# adopted codebase lands in, since its baseline closes STEP-1 without running every session.
# The next action is the planning session, not the open substep.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'implementation not yet outlined.'
assert_contains "$output" 'run the planning session'
assert_absent "$output" 'Run STEP-1.7'
assert_absent "$output" 'Architecture (STEP-1) in progress'

# The same index once the project is building. This is the case that made the defect permanent
# rather than momentary: the substep rule stops the walk, so the STEP in flight was never
# reached and every later status call repeated the architecture answer.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-5 | Build the thing | | In progress | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'Building — STEP-5 (Build the thing) is In progress.'
assert_absent "$output" 'Run STEP-1.7'

# Planned implementation work is likewise reachable underneath a Done STEP-1.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'next up is STEP-2 (Ordinary implementation).'
assert_absent "$output" 'Run STEP-1.7'

# Control: while the STEP-1 row is open, an open substep is still the next action. The gate must
# not cost the rule it guards.
write_index \
'| STEP-1 | Architecture | | In progress | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'Architecture (STEP-1) in progress — 1/2 substeps complete.'
assert_contains "$output" 'Run STEP-1.7: Data Model.'

# Control, the mirror case: substeps all final under a row that is still open means the close-out
# is the work. Both directions are the same rule — the row is what says whether STEP-1 is over.
write_index \
'| STEP-1 | Architecture | | In progress | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Done | architecture/07-data-model.md |'
output="$(run_status)"
assert_contains "$output" 'all 2 substeps are final, but the STEP-1 row is still "In progress".'
assert_contains "$output" 'close out STEP-1'

# Control: an unrecognized substep status is a data problem and outranks both, Done row or not.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Blocked | architecture/07-data-model.md |'
output="$(run_status)"
assert_contains "$output" 'substep(s) with an unrecognized status.'

echo "status.sh STEP-1 row precedence: PASS"
