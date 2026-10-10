#!/usr/bin/env bash
#
# Regression coverage for the STEP-1 row's authority over its own substeps in status.sh, for who
# owns the STEP-1 close-out in a team, for how the resolver reads an Abandoned or zero-padded
# substep, and for how it reports a substep status it does not recognize.
#
# METHOD.md §10 resolves the next action top-down and the first matching rule wins, with the
# index authoritative for which STEP is next. The substep rules sit near the top of that walk,
# so they have to be gated on the STEP-1 row. Without the gate, a STEP-1 marked Done over a
# still-open substep reads as "Architecture (STEP-1) in progress" and sends the reader back into
# an architecture session, and — because that rule stops the walk — keeps reading that way for
# the rest of the project's life, hiding whatever STEP is actually in flight.
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
# Its STEP table keeps the retired Repos (projection) column, as an existing project's index may.
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

# assert_absent OUTPUT UNEXPECTED — fail if OUTPUT holds the wording a case rules out.
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
final_substeps='| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Done | architecture/07-data-model.md |'
reminder="If the Phase-1 planning session hasn't run yet, run it first."

# A STEP-1 row marked Done closes architecture even with sessions left open — the state an
# adopted codebase lands in, since its baseline marks STEP-1 Done and leaves the sessions it ran
# at their Planned seed.
# The next action is the planning session, not the open substep.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'implementation not yet outlined.'
assert_contains "$output" 'run the planning session'
assert_absent "$output" "$reminder"
assert_absent "$output" 'Run STEP-1.7'
assert_absent "$output" 'Architecture (STEP-1) in progress'

# The same index once a later STEP is In progress: the resolver reaches it past the open substep,
# and with work begun it no longer reminds you of the planning session.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-5 | Build the thing | | In progress | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'Building — STEP-5 (Build the thing) is In progress.'
assert_absent "$output" "$reminder"
assert_absent "$output" 'Run STEP-1.7'

# Planned implementation work is likewise reachable underneath a Done STEP-1. Nothing on disk says
# whether the planning session ran, so until a later STEP is In progress or Done the answer ends
# with a reminder of it (METHOD.md §10 rule 3).
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |' \
"$open_substeps"
output="$(run_status)"
assert_contains "$output" 'next up is STEP-2 (Ordinary implementation).'
assert_contains "$output" 'author its PLAN and any substep prompts'
assert_contains "$output" "$reminder"
assert_absent "$output" 'Run STEP-1.7'

# Deferred and Abandoned don't say whether work began, so the reminder stays; Done does.
for later in Deferred Abandoned Done; do
  write_index \
"| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | $later | | Fixture |" \
"$final_substeps"
  output="$(run_status)"
  assert_contains "$output" 'phase looks complete'
  if [ "$later" = Done ]; then
    assert_absent "$output" "$reminder"
  else
    assert_contains "$output" "$reminder"
  fi
done

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
"$final_substeps"
output="$(run_status)"
assert_contains "$output" 'all 2 substeps are final, but the STEP-1 row is still "In progress".'
assert_contains "$output" 'close out STEP-1'
assert_contains "$output" 'The planning session comes after that.'

# The close-out stays the work once the index holds a later STEP. It has to come before every rule
# that reads a later STEP: an In-progress STEP-1 is itself the lowest STEP in flight, so the
# In-progress rule would send it looking for a substep it does not have, and a Planned one would
# leave the answer to STEP-2. With a later STEP in the index the close-out does not name the
# planning session: §10.3 sends you to it only while STEP-1 is the index's only row, and its
# reminder waits for STEP-1 to be Done.
for step1 in 'In progress' 'Planned'; do
  for later in 'Rework the auth boundary | | Planned' \
               'Conditional session: AI feature | | Planned' 'Scaffold repos | | In progress'; do
    write_index \
"| STEP-1 | Architecture | | $step1 | | Fixture |
| STEP-2 | $later | | Fixture |" \
"$final_substeps"
    output="$(run_status)"
    assert_contains "$output" "all 2 substeps are final, but the STEP-1 row is still \"$step1\"."
    assert_contains "$output" 'close out STEP-1'
    assert_absent "$output" 'The planning session comes after that.'
    assert_absent "$output" "$reminder"
    assert_absent "$output" 'ask the user whether STEP-1 is theirs'
  done
done

# In a team the close-out is STEP-1's owner's, since it archives a PLAN that by default is only on
# the owner's machine. A teammate whose own STEP is in flight is asked whether STEP-1 is theirs
# before being told to close it out, as the In-progress rule asks. STEP-1 is Planned here, so the
# STEP in flight is the teammate's, and the owner named has to be STEP-1's, not that STEP's.
write_index \
'| STEP-1 | Architecture | alice | Planned | | Fixture |
| STEP-2 | Scaffold repos | bob | In progress | | Fixture |' \
"$final_substeps"
output="$(run_status)"
assert_contains "$output" 'the STEP-1 row is still "Planned", owned by alice.'
assert_contains "$output" 'ask the user whether STEP-1 is theirs'
assert_contains "$output" "the close-out is alice's to do"
assert_contains "$output" 'close out STEP-1'
assert_absent "$output" 'owned by bob'

# Controls: a Deferred or Abandoned STEP-1 row is not open, and a missing one says nothing, so with
# every substep final the answer passes to the later STEP, and without the planning-session
# reminder, which needs STEP-1 Done.
for step1_row in '| STEP-1 | Architecture | | Deferred | | Fixture |
' '| STEP-1 | Architecture | | Abandoned | | Fixture |
' ''; do
  write_index \
"${step1_row}| STEP-2 | Rework the auth boundary | | Planned | | Fixture |" \
"$final_substeps"
  output="$(run_status)"
  assert_contains "$output" 'next up is STEP-2 (Rework the auth boundary).'
  assert_absent "$output" 'close out STEP-1'
  assert_absent "$output" "$reminder"
done

# Control: with no substep row there is nothing final to close out, so an open STEP-1 row passes
# the answer to the later STEP.
write_index \
'| STEP-1 | Architecture | | Planned | | Fixture |
| STEP-2 | Rework the auth boundary | | Planned | | Fixture |' \
''
output="$(run_status)"
assert_contains "$output" 'next up is STEP-2 (Rework the auth boundary).'
assert_absent "$output" 'close out STEP-1'

# Control: an unrecognized substep status is a data problem and outranks both, Done row or not.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Blocked | architecture/07-data-model.md |'
output="$(run_status)"
assert_contains "$output" 'prompts/STEP-index.md has an unrecognized status on 1 substep row(s): 1.7.'

# The planning-session reminder waits for that fix too, since it would say to run the session first.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Ordinary implementation | | Planned | | Fixture |' \
'| 1.7 | Data Model | Blocked | architecture/07-data-model.md |'
output="$(run_status)"
assert_contains "$output" 'unrecognized status on 1 substep row(s): 1.7.'
assert_absent "$output" "$reminder"

# Every Substep table in the index is read, not only STEP-1's: an index brought up from 1.x keeps
# the substep lists of its finished STEPs. An unrecognized status in one of those is named by its
# row, every such row in turn, and not called a STEP-1 substep.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-5 | Routes | | Done | | Fixture |
| STEP-7 | Payments | | In progress | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |'
printf '\n### STEP-5 substeps\n\n| Substep | Title | Status |\n|---------|-------|--------|\n| 5.1 | Routes | Complete |\n| 5.2 | Webhooks | Blocked |\n' \
  >> "$index"
output="$(run_status)"
assert_contains "$output" 'prompts/STEP-index.md has an unrecognized status on 2 substep row(s): 5.1, 5.2.'
assert_contains "$output" 'fix the substep statuses it lists as invalid'
assert_absent "$output" 'Architecture (STEP-1)'
assert_absent "$output" 'STEP-1 substep'

# An Abandoned substep is final, like Deferred and N/A: the seed legend and check 3 both allow it,
# so it must not read as an unrecognized status, which would outrank the STEP in flight.
write_index \
'| STEP-1 | Architecture | | Done | | Fixture |
| STEP-5 | Build the thing | | In progress | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Abandoned | architecture/07-data-model.md |'
output="$(run_status)"
assert_contains "$output" 'Building — STEP-5 (Build the thing) is In progress.'
assert_absent "$output" 'unrecognized status'

# Final, not open: while STEP-1 is still open, the resolver steps over an Abandoned substep to the
# next open one and counts it among the complete.
write_index \
'| STEP-1 | Architecture | | In progress | | Fixture |' \
'| 1.1 | System Overview | Done | architecture/01-system-overview.md |
| 1.7 | Data Model | Abandoned | architecture/07-data-model.md |
| 1.8 | API Design | Planned | architecture/08-api-design.md |'
output="$(run_status)"
assert_contains "$output" 'in progress — 2/3 substeps complete.'
assert_contains "$output" 'Run STEP-1.8: API Design.'
assert_absent "$output" 'Run STEP-1.7'

# A zero-padded substep number is still a number, on either side of the dot (1.08, 08.1). Read as
# octal, 08 is an arithmetic error; 1.08 is the first open row, so the answer comes out right
# either way, and the error assert is what catches it.
write_index \
'| STEP-1 | Architecture | | In progress | | Fixture |' \
'| 1.07 | Data Model | Done | architecture/07-data-model.md |
| 1.08 | API Design | Planned | architecture/08-api-design.md |
| 08.1 | Later table | Planned | architecture/08-api-design.md |'
output="$(run_status 2>&1)"
assert_contains "$output" 'Run STEP-1.08: API Design.'
assert_absent "$output" 'value too great for base'

echo "status.sh STEP-1 row precedence: PASS"
