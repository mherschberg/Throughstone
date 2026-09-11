#!/usr/bin/env bash
#
# Regression coverage for init.sh local user profile bootstrap output.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-local-profile-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree
# changes so this test covers uncommitted bootstrap edits.
copy_template() {
  local dest="$1" file
  mkdir -p "$dest"
  git -C "$ROOT" archive HEAD | tar -x -C "$dest"
  while IFS= read -r -d '' file; do
    if [ -e "$ROOT/$file" ]; then
      mkdir -p "$dest/$(dirname "$file")"
      cp -p "$ROOT/$file" "$dest/$file"
    else
      rm -f "$dest/$file"
    fi
  done < <(
    {
      git -C "$ROOT" diff --name-only -z HEAD
      git -C "$ROOT" ls-files --others --exclude-standard -z
    }
  )
}

assert_contains() {
  local file="$1" expected="$2"
  grep -Fxq "$expected" "$file" || {
    printf 'FAIL: expected %s to contain exact line: %s\n' "$file" "$expected" >&2
    exit 1
  }
}

assert_profile_output() {
  local work="$1" docs="$2"

  [ -d "$work/.throughstone" ] || {
    printf 'FAIL: root .throughstone directory was not created in %s\n' "$work" >&2
    exit 1
  }
  [ ! -e "$work/.throughstone/local-user.md" ] || {
    printf 'FAIL: init.sh should not create root .throughstone/local-user.md\n' >&2
    exit 1
  }

  assert_contains "$work/.gitignore" "/.throughstone/local-user.md"

  if grep -Eq '^## (Your experience level|Planning communication style)[[:space:]]*$' \
    "$work/$docs/overview.md"; then
    printf 'FAIL: generated overview.md contains legacy local profile section(s)\n' >&2
    exit 1
  fi
}

multi="local-profile-multi"
multi_work="$TMP_ROOT/$multi"
copy_template "$multi_work"
(
  cd "$multi_work"
  ./init.sh \
    --non-interactive \
    --slug="$multi" \
    --desc="Local profile multi test" \
    --license=private \
    --layout=multi \
    --collab=solo \
    --remotes=no
) >"$TMP_ROOT/$multi.out" 2>&1

assert_profile_output "$multi_work" "Code/$multi-docs"
assert_contains "$multi_work/Code/$multi-docs/.gitignore" "/.throughstone/local-user.md"
assert_contains "$multi_work/prompts/.gitignore" "/.throughstone/local-user.md"

# `env -u CI`: check.sh skips its workspace-root hygiene section outright on any non-empty CI,
# so the stray-entry assertion below is unfalsifiable whenever the caller happens to have CI set
# — which is every hosted runner. The variable is pinned here rather than left to whoever invokes
# the test, for the same reason LC_ALL is pinned at the top of this file: an assertion whose
# meaning depends on the ambient environment is not one, and this suite has no runner to pin it
# on our behalf. Nothing else in the bootstrap reads CI, so this scopes to the single command
# whose behaviour it changes.
check_output="$(env -u CI "$multi_work/doctor.sh" check)"
printf '%s\n' "$check_output" | grep -Fq \
  'overview.md has no legacy local user preference sections' || {
    printf 'FAIL: doctor check did not report clean legacy local profile fields\n' >&2
    printf '%s\n' "$check_output" >&2
    exit 1
  }
if printf '%s\n' "$check_output" | grep -Fq 'unexpected entr'; then
  printf 'FAIL: doctor check treated root .throughstone as a stray workspace entry\n' >&2
  printf '%s\n' "$check_output" >&2
  exit 1
fi
# The check above passes on silence, and every way of producing that silence is silent: the
# section skipped for a set CI or for a root that is itself a repo, or a scan that walks nothing
# and reports a clean root over zero inspected entries. So hand the doctor an entry it has to
# name back. A stray file is a warning rather than a failure, so the run still exits 0, and this
# separates "the root was inspected and .throughstone was allowed" from "nothing was looked at".
touch "$multi_work/stray-probe.txt"
probe_output="$(env -u CI "$multi_work/doctor.sh" check)"
rm -f "$multi_work/stray-probe.txt"
printf '%s\n' "$probe_output" | grep -Fq 'stray-probe.txt' || {
  printf 'FAIL: doctor check did not report a stray entry at the workspace root\n' >&2
  printf '%s\n' "$probe_output" >&2
  exit 1
}

mono="local-profile-mono"
mono_work="$TMP_ROOT/$mono"
copy_template "$mono_work"
(
  cd "$mono_work"
  ./init.sh \
    --non-interactive \
    --slug="$mono" \
    --desc="Local profile mono test" \
    --license=private \
    --layout=mono \
    --registries=yes \
    --collab=solo \
    --remotes=no
) >"$TMP_ROOT/$mono.out" 2>&1

assert_profile_output "$mono_work" "Code/$mono-docs"

# In the mono layout the workspace root is the repository, so its ignore file is all that keeps an
# ordinary `git add -A` from committing the in-flight STEP's sheets, which METHOD.md §5 calls
# un-versioned. Ask git rather than reading .gitignore: a line git does not honour would still
# match. The probe is a file the dry run has to name, so a dry run that saw nothing cannot pass, and
# matching the whole output also catches an ignore file the bootstrap commit left modified.
sheet="Upcoming Prompts/$mono-STEP-2-PLAN.md"
printf '# in-flight plan\n' >"$mono_work/$sheet"
printf 'probe\n' >"$mono_work/add-probe.txt"
dry_run="$(git -C "$mono_work" add -A --dry-run)"
rm -f "$mono_work/$sheet" "$mono_work/add-probe.txt"
[ "$dry_run" = "add 'add-probe.txt'" ] || {
  printf 'FAIL: git add -A in a fresh mono project should list only add-probe.txt, not %s; got:\n' \
    "$sheet" >&2
  printf '%s\n' "$dry_run" >&2
  exit 1
}
# Only the folder's contents are ignored: its placeholder stays committed, so a clone of a mono
# project still has the folder the next PLAN is written into.
git -C "$mono_work" ls-files --error-unmatch "Upcoming Prompts/.gitkeep" >/dev/null 2>&1 || {
  printf 'FAIL: the mono bootstrap commit does not track Upcoming Prompts/.gitkeep\n' >&2
  exit 1
}

echo "init.sh local user profile output: PASS"
