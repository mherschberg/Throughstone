#!/usr/bin/env bash
#
# Regression coverage for the scheduled check-in in status.sh.
#
# overview.md's `<!-- NEXT-CHECK-IN: … -->` line holds a STEP number or an ISO date. status.sh
# reports it as due once that point is reached and keeps saying so; anything it cannot read —
# including a missing line — reads as "none scheduled". Nothing here is validated anywhere else,
# so this file is the only thing standing between a malformed value and a wrong report.
#
# It also holds METHOD.md §10 rule 7's contract: the check-in advises and proposes, and never
# becomes the next action. An overdue project must still be told to get on with its next STEP —
# the case at the end asserts both halves, because a gate would satisfy every assertion above
# while breaking the rule they exist to serve.

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

# --- A STEP number: due once the index reaches it, and from then on ------------
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 12)" 'next at STEP-20 (the project is at STEP-12).'
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 20)" 'due — scheduled for STEP-20, and the project is at STEP-20.'
has "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 41)" 'due — scheduled for STEP-20, and the project is at STEP-41.'

# A hand-written leading zero is base 10, not octal. Read as octal it aborts the arithmetic and
# takes the whole resolver down with it, so the next action disappears too — assert both. The
# number is printed normalised, so the line reports what was read rather than what was typed.
zero="$(run '<!-- NEXT-CHECK-IN: STEP-08 -->' 12)"
has "$zero" 'due — scheduled for STEP-8, and the project is at STEP-12.'
has "$zero" 'plan STEP-12'

# --- A date: compared against today, no arithmetic ----------------------------
today="$(date +%F)"
has "$(run '<!-- NEXT-CHECK-IN: 2999-01-15 -->' 12)" "next on 2999-01-15 (today is $today)."
has "$(run '<!-- NEXT-CHECK-IN: 2000-01-15 -->' 12)" 'due — scheduled for 2000-01-15.'
has "$(run "<!-- NEXT-CHECK-IN: $today -->" 12)"     "due — scheduled for $today."

# --- Anything unreadable, or nothing at all, is "none scheduled" ---------------
# This is the floor: a project can lose the line, or write nonsense into it, and still be told to
# schedule one. Nothing validates the value, so this message is the only place a typo surfaces —
# which is why the two cases have to read differently. A single "none scheduled" for both would
# send someone hunting for a line that is sitting right there with a typo in it.
for marker in '<!-- NEXT-CHECK-IN: sometime soon -->' '<!-- NEXT-CHECK-IN: STEP-20x -->' \
              '<!-- NEXT-CHECK-IN: 2026-13 -->'; do
  out="$(run "$marker" 12)"
  has "$out" 'none scheduled —'
  has "$out" 'which is neither a STEP number'
done
# An empty value is a present-but-unreadable line too, but there is nothing to quote back, so it
# reads as the absent case.
for marker in '' '<!-- NEXT-CHECK-IN: -->'; do
  out="$(run "$marker" 12)"
  has "$out" 'none scheduled — add a NEXT-CHECK-IN line'
done

# Two lines: the first wins. Nothing forbids a second, and a stale one left above the live one
# would otherwise change the answer silently depending on which the extraction happened to reach.
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

# The position follows the resolver's own precedence, so the two halves of the output can never
# name different STEPs. A lower Planned row sitting under an active one is the case that separates
# precedence from "lowest of the three": taking the lowest said the project was at STEP-3 while the
# next action said to open STEP-4, and called a check-in scheduled at STEP-4 not yet due.
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
# is offered beside it, marked as advice. Rule 7 sits after rule 5 in §10 for this reason, and
# the wording is asserted so an "insert a Check-in STEP now" imperative cannot creep back in.
out="$(run '<!-- NEXT-CHECK-IN: STEP-2 -->' 41)"
has "$out" 'due — scheduled for STEP-2'
has "$out" 'plan STEP-41'
has "$out" 'Also worth proposing: a Check-in STEP'
has "$out" 'Advice, not a gate'
hasnt "$out" 'insert a Check-in STEP now'

# A project that is not there yet is not offered one at all.
hasnt "$(run '<!-- NEXT-CHECK-IN: STEP-20 -->' 12)" 'Also worth proposing'

echo "status.sh scheduled check-in: PASS"
