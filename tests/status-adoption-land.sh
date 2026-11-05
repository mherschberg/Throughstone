#!/usr/bin/env bash
#
# Regression coverage for how status.sh reads an adoption's land (RETCON-PROMPT.md Stage 4).
#
# The land leaves an adopted project in a state no greenfield project reaches: STEP-1 is Done
# with a Scope opening "Retcon baseline —", its N/A and Deferred sessions and lettered conditional
# rows are written into the index, and every other session row stays at the Planned seed. The
# land adds no resolver logic, so status.sh has to read that state exactly as it reads a greenfield
# project whose architecture STEP is Done: same next action, same check-in. The one difference is
# the substep tally on the "Where you are" line, which counts the Planned rows the land leaves.
#
# The land flips PROJECT-STATUS to kickoff-complete last. A land interrupted before the flip has
# already rewritten the index into its landed shape, and must still route back to the adoption
# prompt, which finishes the land, rather than on to the planning session.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-adoption-land-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# write_index FILE STEP1_STATUS STEP1_SCOPE SUB_ROWS — the seed's two tables, Phase 1 named.
write_index() {
  {
    printf '# Resolver fixture\n\n## Phase 1 — MVP\n\n'
    printf '| STEP | Title | Owner | Status | Scope (one line) |\n'
    printf '|------|-------|-------|--------|------------------|\n'
    printf '| STEP-1 | Architecture | | %s | %s |\n\n' "$2" "$3"
    printf '### STEP-1 substeps (architecture sessions)\n\n'
    printf '| Substep | Session | Status | Output doc |\n'
    printf '|---------|---------|--------|------------|\n'
    printf '%s\n' "$4"
  } > "$1"
}

# sessions STATUS — the fourteen core rows plus one lettered conditional. The conditional ran, the
# UI session does not apply and observability was deferred, so those three keep their statuses in
# both projects; every other core row takes STATUS.
sessions() {
  local n
  for n in 1 2 3 4 5 6; do printf '| 1.%s | Session %s | %s | x |\n' "$n" "$n" "$1"; done
  printf '| 1.6a | Identity & Auth | Done | x |\n'
  printf '| 1.7 | UI / Design System | N/A | x |\n'
  for n in 8 9; do printf '| 1.%s | Session %s | %s | x |\n' "$n" "$n" "$1"; done
  printf '| 1.10 | Observability | Deferred | x |\n'
  for n in 11 12 13; do printf '| 1.%s | Session %s | %s | x |\n' "$n" "$n" "$1"; done
  printf '| 1.14 | Cross-Cutting Review | %s | review doc |\n' "$1"
}

# write_overview FILE MARKER [EXTRA_LINE]
write_overview() {
  {
    printf '<!-- PROJECT-STATUS: %s -->\n<!-- NEXT-CHECK-IN: STEP-20 -->\n# Overview\n' "$2"
    if [ -n "${3:-}" ]; then printf '\n%s\n' "$3"; fi
  } > "$1"
}

run_status() {
  THROUGHSTONE_STEP_INDEX="$1" THROUGHSTONE_OVERVIEW="$2" "$STATUS"
}

# without_tally — drop the "(k/N substeps)" count, the one part allowed to differ.
without_tally() {
  sed -E 's/ \([0-9]+\/[0-9]+ substeps\)//'
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

retcon_scope='Retcon baseline — reverse-engineered from existing code; adopted 2026-11-04; forward work starts at STEP-2.'
provenance='Adopted via retcon on 2026-11-04.'

green_index="$TMP_ROOT/green-index.md"
green_overview="$TMP_ROOT/green-overview.md"
write_index "$green_index" Done 'Architecture-first: design docs + ADRs, no code.' "$(sessions Done)"
write_overview "$green_overview" kickoff-complete

landed_index="$TMP_ROOT/landed-index.md"
landed_overview="$TMP_ROOT/landed-overview.md"
write_index "$landed_index" Done "$retcon_scope" "$(sessions Planned)"
write_overview "$landed_overview" kickoff-complete "$provenance"

# 1. A landed adoption resolves exactly as a greenfield project with a Done STEP-1.
green="$(run_status "$green_index" "$green_overview")"
landed="$(run_status "$landed_index" "$landed_overview")"
assert_contains "$landed" "Architecture (STEP-1) complete"
assert_contains "$landed" "run the planning session"
refute_contains "$landed" "RETCON-PROMPT.md"
if [ "$(printf '%s\n' "$green" | without_tally)" != "$(printf '%s\n' "$landed" | without_tally)" ]; then
  printf 'FAIL: a landed adoption resolves differently from a greenfield project with a Done STEP-1\n' >&2
  diff <(printf '%s\n' "$green" | without_tally) <(printf '%s\n' "$landed" | without_tally) >&2 || true
  exit 1
fi

# 2. A land interrupted before the marker flip still routes back to the adoption prompt, even with
#    every other act already on disk.
interrupted_overview="$TMP_ROOT/interrupted-overview.md"
write_overview "$interrupted_overview" retcon "$provenance"
interrupted="$(run_status "$landed_index" "$interrupted_overview")"
assert_contains "$interrupted" "retcon in progress — follow"
assert_contains "$interrupted" "RETCON-PROMPT.md"
refute_contains "$interrupted" "planning session"

echo "PASS: status.sh reads a landed adoption as a greenfield baseline, and an unflipped land as an adoption"
