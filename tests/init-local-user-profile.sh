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

check_output="$("$multi_work/doctor.sh" check)"
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

echo "init.sh local user profile output: PASS"
