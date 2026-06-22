#!/usr/bin/env bash
#
# Minimal gh repo create stub for local init.sh integration tests.
#
# Required env:
#   GH_LOG          append-only command log inspected by tests
#   GH_REMOTE_ROOT  directory where local bare remotes are created

set -euo pipefail

printf '%s\n' "$*" >> "$GH_LOG"

# Only `gh repo create OWNER/NAME ...` is modeled. The stub creates a local bare repository
# and adds it as origin in the current checkout, matching the init.sh side effects under test.
if [ "${1:-}" != "repo" ] || [ "${2:-}" != "create" ] || [ -z "${3:-}" ]; then
  echo "gh-stub.sh: unsupported command: $*" >&2
  exit 2
fi

repo_name="${3##*/}"
remote="$GH_REMOTE_ROOT/$repo_name.git"
git init --bare -q "$remote"
git remote add origin "$remote"
