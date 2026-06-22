#!/usr/bin/env bash
#
# Regression coverage for init.sh trunk branch selection.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-trunk-test.XXXXXX")"
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

assert_no_ref() {
  local git_dir="$1" ref="$2"
  ! git --git-dir="$git_dir" rev-parse --verify "$ref" >/dev/null 2>&1
}

run_default_case() {
  local name="trunk-default"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch default test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work/Code/$name-docs" symbolic-ref --short HEAD)" = "main" ]
  [ "$(git -C "$work/prompts" symbolic-ref --short HEAD)" = "main" ]
  grep -Fq '**shared trunk** (`main`)' \
    "$work/Code/$name-docs/runbooks/collaboration.md"
  ! grep -R '{{TRUNK_BRANCH}}' "$work/Code/$name-docs" "$work/prompts" >/dev/null
}

run_manual_remote_custom_case() {
  local name="trunk-master"
  local work="$TMP_ROOT/$name"
  local docs_remote="$TMP_ROOT/$name-docs.git"
  local prompts_remote="$TMP_ROOT/$name-prompts.git"

  copy_template "$work"
  git init --bare -q "$docs_remote"
  git init --bare -q "$prompts_remote"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch manual remote test" \
      --license=private \
      --layout=multi \
      --collab=team \
      --adr-authority="consensus of maintainers" \
      --trunk-branch=master \
      --remotes=yes \
      --remote-provider=manual \
      --docs-remote="$docs_remote" \
      --prompts-remote="$prompts_remote"
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work/Code/$name-docs" symbolic-ref --short HEAD)" = "master" ]
  [ "$(git -C "$work/prompts" symbolic-ref --short HEAD)" = "master" ]
  git --git-dir="$docs_remote" rev-parse --verify refs/heads/master >/dev/null
  git --git-dir="$prompts_remote" rev-parse --verify refs/heads/master >/dev/null
  assert_no_ref "$docs_remote" refs/heads/main
  assert_no_ref "$prompts_remote" refs/heads/main
  git --git-dir="$docs_remote" show master:registries/repos.yml \
    | grep -Fq "remote: \"$docs_remote\""
  grep -Fq '**shared trunk** (`master`)' \
    "$work/Code/$name-docs/runbooks/collaboration.md"
  grep -Fq "push each local repo's master branch" "$TMP_ROOT/$name.out"
}

run_mono_reused_origin_custom_case() {
  local name="trunk-mono"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"

  copy_template "$work"
  git init --bare -q "$remote"
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch mono origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --trunk-branch=release/stable \
      --remotes=yes
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" symbolic-ref --short HEAD)" = "release/stable" ]
  git --git-dir="$remote" rev-parse --verify refs/heads/release/stable >/dev/null
  assert_no_ref "$remote" refs/heads/main
  grep -Fq "pushed: $remote" "$TMP_ROOT/$name.out"
}

run_invalid_case() {
  local name="$1"
  local branch_arg="$2"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  if (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Invalid trunk branch test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no \
      "$branch_arg"
  ) >"$TMP_ROOT/$name.out" 2>&1; then
    echo "FAIL: invalid trunk branch was accepted: $branch_arg" >&2
    return 1
  fi

  grep -Fq "init.sh: invalid --trunk-branch" "$TMP_ROOT/$name.out"
  [ -f "$work/README.md" ]
  [ -d "$work/Code/{{PROJECT}}-docs" ]
}

run_default_case
run_manual_remote_custom_case
run_mono_reused_origin_custom_case
run_invalid_case "trunk-empty" "--trunk-branch="
run_invalid_case "trunk-dotdot" "--trunk-branch=bad..name"
run_invalid_case "trunk-dash" "--trunk-branch=-bad"

echo "init.sh trunk branch selection: PASS"
