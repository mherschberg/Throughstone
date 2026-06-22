#!/usr/bin/env bash
#
# doctor.sh — root Throughstone doctor wrapper.
#
# Locate the generated docs hub from the workspace root, then delegate to the single dispatcher
# implementation in Code/<project>-docs/scripts/doctor.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# find_docs_dir — locate the generated docs hub from the workspace root.
# Scaffold checkouts keep the literal Code/{{PROJECT}}-docs path; initialized projects replace
# it with Code/<project>-docs. Ambiguous matches are rejected so the dispatcher never guesses.
find_docs_dir() {
  local candidate
  candidate="$ROOT/Code/{{PROJECT}}-docs"
  if [ -d "$candidate/scripts" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  local matches=()
  shopt -s nullglob
  matches=("$ROOT"/Code/*-docs/scripts)
  shopt -u nullglob

  if [ "${#matches[@]}" -eq 1 ]; then
    cd "${matches[0]}/.."
    pwd
    return 0
  fi

  if [ "${#matches[@]}" -eq 0 ]; then
    echo "doctor.sh: could not find Code/<project>-docs/scripts" >&2
  else
    echo "doctor.sh: found multiple Code/*-docs/scripts directories; run the intended helper directly" >&2
  fi
  return 1
}

# Delegate to the docs hub's dispatcher so command behavior has exactly one implementation.
docs_dir="$(find_docs_dir)"
script="$docs_dir/scripts/doctor.sh"

if [ ! -x "$script" ]; then
  echo "doctor.sh: dispatcher is missing or not executable: $script" >&2
  exit 1
fi

exec "$script" "$@"
