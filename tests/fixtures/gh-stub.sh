#!/usr/bin/env bash
#
# Minimal gh repo create stub for local init.sh integration tests.

set -euo pipefail

printf '%s\n' "$*" >> "$GH_LOG"

if [ "${1:-}" != "repo" ] || [ "${2:-}" != "create" ] || [ -z "${3:-}" ]; then
  echo "gh-stub.sh: unsupported command: $*" >&2
  exit 2
fi

repo_name="${3##*/}"
remote="$GH_REMOTE_ROOT/$repo_name.git"
git init --bare -q "$remote"
git remote add origin "$remote"
