#!/usr/bin/env bash
#
# Regression coverage for what status.sh says when there is no STEP index.
#
# Before setup there is no overview.md and no index, and the answer is ./init.sh. After setup
# ./init.sh is the wrong answer: it refuses to run in an initialized project. So the init.sh
# advice needs overview.md to be absent too, and an initialized project is told how to get the
# index back. The kickoff gate comes first: a project not yet kicked off is told to start it.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/Code/{{PROJECT}}-docs/scripts/status.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-no-roadmap-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

OVERVIEW="$TMP_ROOT/overview.md"
INDEX="$TMP_ROOT/STEP-index.md"   # never written: no case here has an index

run() {
  THROUGHSTONE_OVERVIEW="$OVERVIEW" THROUGHSTONE_STEP_INDEX="$INDEX" "$STATUS"
}

# overview MARKER — write an overview.md carrying the kickoff marker MARKER.
overview() {
  printf '# Fixture — Project Overview\n\n<!-- PROJECT-STATUS: %s -->\n' "$1" > "$OVERVIEW"
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

# Before setup: no overview.md, no index.
out="$(run)"
has "$out" 'project not initialized'
has "$out" 'run ./init.sh'

# After the kickoff, with no index.
overview kickoff-complete
out="$(run)"
has "$out" 'no roadmap (no prompts/STEP-index.md in this workspace)'
has "$out" 'restore prompts/STEP-index.md from git history'
has "$out" 'scripts/setup-workspace.sh to clone it'
hasnt "$out" 'not initialized'
hasnt "$out" 'run ./init.sh'

# Before the kickoff, with no index.
overview not-started
out="$(run)"
has "$out" 'start the kickoff'
hasnt "$out" 'run ./init.sh'

echo "status.sh with no STEP index: PASS"
