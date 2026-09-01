#!/usr/bin/env bash
#
# Minimal gh repo create stub for local init.sh integration tests.
#
# Required env:
#   GH_LOG          append-only command log inspected by tests
#   GH_REMOTE_ROOT  directory where local bare remotes are created

set -euo pipefail

printf '%s\n' "$*" >> "$GH_LOG"

# Only `gh repo create OWNER/NAME ...` is modeled. The stub creates a local bare repository,
# adds it as origin in the current checkout, and pushes -- matching the init.sh side effects
# under test.
#
# The push is the point, not a detail. init.sh invokes this with --push and treats a zero exit
# as proof that the branch is on the remote: on that basis it records the remote's URL in
# registries/repos.yml. A stub that created the repository and stopped reported success for an
# upload that had not happened, so the tests modelled init.sh recording a remote for a provably
# empty repository -- the one thing the registry is supposed never to claim.
if [ "${1:-}" != "repo" ] || [ "${2:-}" != "create" ] || [ -z "${3:-}" ]; then
  echo "gh-stub.sh: unsupported command: $*" >&2
  exit 2
fi

# The side effects are driven by the options, not assumed. `gh repo create` only attaches a
# remote when told which local checkout to use and what to call it, and only uploads when told to
# -- so a stub that always did both would keep reporting success after those options were dropped
# from init.sh, and the tests would not notice. Model the contract; do not stand in for it.
want_source=0; want_remote=""; want_push=0
for arg in "$@"; do
  case "$arg" in
    --source=.)   want_source=1 ;;
    --remote=*)   want_remote="${arg#--remote=}" ;;
    --push)       want_push=1 ;;
  esac
done

repo_name="${3##*/}"
remote="$GH_REMOTE_ROOT/$repo_name.git"
git init --bare -q "$remote"

# --source tells gh which checkout to attach; without it there is nothing to attach or upload.
[ "$want_source" = "1" ] || exit 0
[ -n "$want_remote" ] && git remote add "$want_remote" "$remote"
if [ "$want_push" = "1" ] && [ -n "$want_remote" ]; then
  branch="$(git symbolic-ref --short HEAD)"
  git push -q -u "$want_remote" "$branch"
  # A real host leaves the created repository pointing at the branch it received. Without this the
  # bare repo's HEAD names the branch `git init` defaulted to, which never arrives, and a later
  # clone of it checks nothing out.
  git --git-dir="$remote" symbolic-ref HEAD "refs/heads/$branch"
fi
