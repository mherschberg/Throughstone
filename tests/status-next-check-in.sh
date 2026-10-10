#!/usr/bin/env bash
#
# Regression coverage for the scheduled check-in in status.sh.
#
# overview.md's `<!-- NEXT-CHECK-IN: … -->` line holds a STEP number or an ISO date. status.sh
# reports it as due once that point is reached and keeps saying so; anything it cannot read —
# including a missing line — reads as "none scheduled".
#
# This file also tests METHOD.md §10 rule 7's contract, for a check-in scheduled by STEP number:
# the check-in advises and proposes, and never becomes the next action. An overdue project must
# still be told to get on with its next STEP, so the rule 7 case asserts the next action, the
# proposal beside it and the proposal's wording. No other case would catch a gate that fires only
# when the project is badly overdue.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-in-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

OVERVIEW="$TMP_ROOT/overview.md"
INDEX="$TMP_ROOT/STEP-index.md"

# run MARKER MAXSTEP — seed an overview carrying MARKER (empty to omit the line) and an index
# whose highest row is STEP-MAXSTEP, then return status.sh's output.
# Both tables in this file keep the retired Repos (projection) column, as an existing project's
# index may.
run() {
  {
    printf '# Fixture — Project Overview\n\n'
    [ -n "$1" ] && printf '%s\n' "$1"
    printf '<!-- PROJECT-STATUS: kickoff-complete -->\n'
  } > "$OVERVIEW"
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    printf '| STEP-1 | Architecture | | Done | | Fixture |\n'
    printf '| STEP-%s | Later work | | Planned | | Fixture |\n' "$2"
  } > "$INDEX"
  THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS"
}

has() {
  if ! printf '%s\n' "$1" | grep -Fq "$2"; then
    printf 'FAIL: expected status output to contain: %s\n' "$2" >&2
    printf '%s\n' "$1" >&2
    exit 1
  fi
}
hasnt() {
  if printf '%s\n' "$1" | grep -Fq "$2"; then
    printf 'FAIL: status output should not contain: %s\n' "$2" >&2
    printf '%s\n' "$1" >&2
    exit 1
  fi
}

# --- A STEP number: due once the project reaches it, and from then on ----------
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 12)" 'next at STEP-20 (the project is at STEP-12).'
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 20)" 'due — scheduled for STEP-20, and the project is at STEP-20.'
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 41)" 'due — scheduled for STEP-20, and the project is at STEP-41.'

# A hand-written leading zero is base 10, not octal. Read as octal, 08 is an arithmetic error:
# status.sh prints the next action, then exits 1 where the check-in line should be, and set -e
# stops this test at the assignment below. The number is printed normalised, so the line reports
# what was read rather than what was typed.
zero="$(run '<!-- NEXT-CHECK-IN: STEP-08 -->' 12)"
has "$zero" 'due — scheduled for STEP-8, and the project is at STEP-12.'
has "$zero" 'plan STEP-12'

# --- A date: compared against today, no arithmetic ----------------------------
# Whether the proposal is offered is asserted on both date arms, not just the wording of the
# line. One flag carries it, and each arm decides it separately, so asserting it on the STEP arms
# alone would let a date-scheduled project stop being offered a check-in, or start being offered
# one before it is due, without a single test noticing.
today="$(date +%F)"
future="$(run '<!-- NEXT-CHECK-IN: 2999-01-15 -->' 12)"
has   "$future" "next on 2999-01-15 (today is $today)."
hasnt "$future" 'Also worth proposing'
past="$(run '<!-- NEXT-CHECK-IN: 2000-01-15 -->' 12)"
has "$past" 'due — scheduled for 2000-01-15.'
has "$past" 'Also worth proposing: a Check-in STEP'
has "$(run "<!-- NEXT-CHECK-IN: $today -->" 12)"     "due — scheduled for $today."

# --- Anything unreadable, or nothing at all, is "none scheduled" ---------------
# This is the floor: a project can lose the line, or write nonsense into it, and still be told to
# schedule one. Nothing validates the value, so this message is the only place a typo surfaces —
# which is why the two cases have to read differently. A single "none scheduled" for both would
# send someone hunting for a line that is sitting right there with a typo in it. Being told to
# schedule one is the proposal block, so both cases assert that too: the floor is the offer, not
# the wording of the line reporting there is nothing to offer against.
for marker in '<!-- NEXT-CHECK-IN: sometime soon -->' '<!-- NEXT-CHECK-IN: STEP-20x -->' \
              '<!-- NEXT-CHECK-IN: 2026-13 -->'; do
  out="$(run "$marker" 12)"
  has "$out" 'none scheduled —'
  has "$out" 'which is neither a STEP number'
  has "$out" 'Also worth proposing: a Check-in STEP'
done
# An empty value is a present-but-unreadable line too, but there is nothing to quote back, so it
# reads as the absent case.
for marker in '' '<!-- NEXT-CHECK-IN: -->'; do
  out="$(run "$marker" 12)"
  has "$out" 'none scheduled — add a NEXT-CHECK-IN line'
  has "$out" 'Also worth proposing: a Check-in STEP'
done

# Two lines: the first wins, and this case pins that. Nothing forbids a second, so a stale line
# left above the live one is the one reported.
two="$(run '<!-- NEXT-CHECK-IN: STEP-99 -->
<!-- NEXT-CHECK-IN: STEP-2 -->' 12)"
has "$two" 'next at STEP-99 (the project is at STEP-12).'

# --- "Reached" means the project got there, not that the roadmap was drawn that far ---
# The planning session writes a whole phase of Planned rows at once, so the index's highest row is
# where the phase ENDS. Measuring against it reports every freshly-planned phase as due on its
# first day — and the fixtures above cannot catch that, because each seeds only two rows, which
# makes the highest row and the project's position the same number by construction.
# run_rows [MARKER_VALUE] — rows on stdin; the marker defaults to STEP-20.
run_rows() {
  {
    printf '# Fixture — Project Overview\n\n'
    printf '<!-- NEXT-CHECK-IN: %s -->\n<!-- PROJECT-STATUS: kickoff-complete -->\n' "${1:-STEP-20}"
  } > "$OVERVIEW"
  {
    printf '# Resolver fixture\n\n'
    printf '| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |\n'
    printf '|------|-------|-------|--------|--------------------|------------------|\n'
    cat
  } > "$INDEX"
  THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS"
}

# Work is at STEP-2; the phase is outlined to STEP-25, with the check-in row already sitting at
# STEP-20. Not due, and no proposal.
outlined="$(run_rows <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-2 | Build the thing | | In progress | | Fixture |
| STEP-3 | More work | | Planned | | Fixture |
| STEP-20 | Check-in | | Planned | | Fixture |
| STEP-25 | Last one | | Planned | | Fixture |
ROWS
)"
has "$outlined" 'next at STEP-20 (the project is at STEP-2).'
hasnt "$outlined" 'Also worth proposing'

# Work reaches it: due.
arrived="$(run_rows <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-19 | Earlier work | | Done | | Fixture |
| STEP-20 | Check-in | | In progress | | Fixture |
| STEP-25 | Last one | | Planned | | Fixture |
ROWS
)"
has "$arrived" 'due — scheduled for STEP-20, and the project is at STEP-20.'

# The check-in ran but nobody moved the line: it keeps saying due, which is the point.
stale="$(run_rows <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-20 | Check-in | | Done | | Fixture |
| STEP-21 | Next thing | | Planned | | Fixture |
| STEP-25 | Last one | | Planned | | Fixture |
ROWS
)"
has "$stale" 'due — scheduled for STEP-20, and the project is at STEP-21.'

# Every row final — the phase is over, so the highest row IS the position (METHOD.md §10.8).
done_phase="$(run_rows <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-25 | Last one | | Done | | Fixture |
ROWS
)"
has "$done_phase" 'due — scheduled for STEP-20, and the project is at STEP-25.'

# The position is the lowest In-progress STEP, else the lowest Planned one after STEP-1, else the
# highest row. In the next two cases that is the STEP the next action names, so the check-in line
# and the next action agree there. A Planned row numbered below an In-progress one tells this
# apart from taking the lowest open row, which would say the project is at STEP-3 while the next
# action says to open STEP-4, and call a check-in scheduled at STEP-4 not yet due.
skipped="$(run_rows STEP-4 <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-3 | Skipped for now | | Planned | | Fixture |
| STEP-4 | Current work | | In progress | | Fixture |
ROWS
)"
has "$skipped" 'open STEP-4'
has "$skipped" 'the project is at STEP-4.'

# Nothing in progress: the lowest Planned row is the position, matching rule 5's answer.
planned_only="$(run_rows <<'ROWS'
| STEP-1 | Architecture | | Done | | Fixture |
| STEP-21 | Next up | | Planned | | Fixture |
ROWS
)"
has "$planned_only" 'plan STEP-21'
has "$planned_only" 'due — scheduled for STEP-20, and the project is at STEP-21.'

# A padded number is read as base 10 and printed normalised, so the line says what was read.
padded="$(run "<!-- NEXT-CHECK-IN: STEP-020 -->" 12)"
has "$padded" 'next at STEP-20 (the project is at STEP-12).'

# --- It advises; it never becomes the next action (METHOD.md §10 rule 7) -------
# A badly overdue project with a Planned STEP still resolves to planning that STEP. The check-in
# is offered beside it, marked as advice: §10 takes the first rule that matches, but rule 7 is
# reported alongside the next action and never in place of it. The last assert keeps out
# the imperative "insert a Check-in STEP now", and only as that exact, case-sensitive phrase.
out="$(run '<!-- NEXT-CHECK-IN: STEP-2 -->' 41)"
has "$out" 'due — scheduled for STEP-2'
has "$out" 'plan STEP-41'
has "$out" 'Also worth proposing: a Check-in STEP'
has "$out" 'Advice, not a gate'
hasnt "$out" 'insert a Check-in STEP now'

# A project that is not there yet is not offered one at all.
hasnt "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 12)" 'Also worth proposing'

echo "status.sh scheduled check-in: PASS"
