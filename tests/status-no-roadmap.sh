#!/usr/bin/env bash
#
# Regression coverage for what status.sh says when there is no STEP index.
#
# Before setup there is no overview.md and no index, and the answer is ./init.sh. After setup
# ./init.sh is the wrong answer: it refuses to run in an initialized project. So the init.sh
# advice needs overview.md to be absent too, and an initialized project is told how to get the
# index back. The kickoff gate comes first: a project not yet kicked off is told to start it. A
# folder where setup stopped partway is told to start again from a fresh copy, since init.sh
# refuses to run there as well.

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
  if ! grep -Fq "$2" <<<"$1"; then
    printf 'FAIL: expected status output to contain: %s\n' "$2" >&2
    printf '%s\n' "$1" >&2
    exit 1
  fi
}
hasnt() {
  if grep -Fq "$2" <<<"$1"; then
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

# Setup that stopped partway: no overview.md and no index, the template marker still in the root
# AGENTS.md, and README.md and .github/ gone. init.sh refuses to run there, so ./init.sh is the
# wrong answer and a fresh copy is the right one. status.sh finds the workspace root from where it
# sits, so this case runs a copy of it inside a workspace laid out that way.
half="$TMP_ROOT/half"
mkdir -p "$half/Code/{{PROJECT}}-docs/scripts"
cp "$STATUS" "$half/Code/{{PROJECT}}-docs/scripts/status.sh"
cp "$ROOT/AGENTS.md" "$half/AGENTS.md"
half_run() {
  THROUGHSTONE_OVERVIEW="$TMP_ROOT/absent-overview.md" THROUGHSTONE_STEP_INDEX="$INDEX" \
    "$half/Code/{{PROJECT}}-docs/scripts/status.sh"
}
out="$(half_run)"
has "$out" 'setup stopped partway'
has "$out" 'download the template into a new, empty folder'
hasnt "$out" 'project not initialized'

# …and with either README.md or .github/ still there, setup had not got that far, and the answer
# is ./init.sh as before.
: > "$half/README.md"
out="$(half_run)"
has "$out" 'project not initialized'
hasnt "$out" 'setup stopped partway'
rm "$half/README.md"
mkdir "$half/.github"
out="$(half_run)"
has "$out" 'project not initialized'
hasnt "$out" 'setup stopped partway'

echo "status.sh with no STEP index: PASS"
