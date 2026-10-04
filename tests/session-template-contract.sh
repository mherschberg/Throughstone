#!/usr/bin/env bash
#
# Contract coverage for templates/architecture-sessions/*.md.
#
# Session files are read by more than the agent running the session: the Cross-Cutting Review
# enumerates every conditional, the periodic check-in re-evaluates them, and existing-codebase
# adoption harvests their work lists. Those readers key on structure, so the structure is a
# contract rather than a per-file style choice.
#
# Asserts, across every session template:
#   - The shared section skeleton, in order, with one work-list heading name for all of them
#     (`## Decisions to make (in order)` — even where the items are checks or term batches,
#     which those files explain in a note beneath the heading).
#   - The closing go-ahead is conditional on having been sent to run the session, and says so
#     in the same words in every file — no copy drifting into a weaker or contradictory promise.
#
# This runs against the template repo, not a generated project. check.sh reads these templates
# too, but only for their numbering against the STEP-index seed and the conditional ones'
# contract (checks 8 and 9); only this file checks the full skeleton and the go-ahead wording.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSIONS="$ROOT/Code/{{PROJECT}}-docs/templates/architecture-sessions"

SKELETON="About {{PROJECT}}|What this session does|Why this session matters|How this session works|Decisions to make (in order)|Output|Next|"
OPENER='**If you were sent here to run this session, begin now — in this same reply.**'
DISCLAIMER='**If you were not sent here to run it'

fail() { echo "FAIL: $*" >&2; exit 1; }

shopt -s nullglob
templates=("$SESSIONS"/*.md)
[ ${#templates[@]} -gt 0 ] || fail "no session templates found under $SESSIONS"

tail_clause=""
for f in "${templates[@]}"; do
  b="$(basename "$f")"

  # 1. Same sections, same order, same work-list heading — including the two sessions whose
  #    items are not literally decisions.
  actual="$(grep -E '^## ' "$f" | sed 's/^## //' | tr '\n' '|')"
  [ "$actual" = "$SKELETON" ] || fail "$b section skeleton differs from the contract:
  expected: $SKELETON
  actual:   $actual"

  # 2. The go-ahead fires on being sent to run the session, not on being read.
  grep -qF "$OPENER" "$f" || fail "$b go-ahead is not conditional on having been sent to run it"
  grep -qF "$DISCLAIMER" "$f" || fail "$b go-ahead does not release a reader who was not sent here"

  # 3. Both sentences of the release clause in the same words everywhere: presence alone would
  #    pass a file whose wording had been weakened while its siblings kept the original. A failed
  #    extraction is reported as a malformed clause. Otherwise the clause must match the first
  #    template's, once spaces and newlines are collapsed: the templates wrap it differently.
  clause="$(tr -s ' \n' ' ' <"$f" \
    | grep -oE 'If you were not sent here to run it.*follow whatever sent you here\.')" \
    || fail "$b release clause is malformed (could not extract it)"
  if [ -z "$tail_clause" ]; then
    tail_clause="$clause"
  elif [ "$clause" != "$tail_clause" ]; then
    fail "$b release clause differs in wording from the other session templates:
  expected: $tail_clause
  actual:   $clause"
  fi
done

echo "session template contract (${#templates[@]} templates): PASS"
