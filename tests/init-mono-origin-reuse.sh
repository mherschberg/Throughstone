#!/usr/bin/env bash
#
# Regression coverage for mono-repo reuse of an existing root origin.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-mono-origin-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST - copy HEAD plus current working-tree changes, without Git metadata.
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

commit_all() {
  git -c user.name="Throughstone Test" \
    -c user.email="throughstone-test@example.invalid" \
    commit -qm "$1"
}

run_non_empty_origin_case() {
  local name="mono-template-origin"
  local seed="$TMP_ROOT/$name-seed"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"

  copy_template "$seed"
  (
    cd "$seed"
    git init -q
    git add -A
    commit_all "Template-created commit"
    git branch -M main
    git init --bare -q "$remote"
    git remote add origin "$remote"
    git push -q -u origin main
  )
  git clone -q -b main "$remote" "$work"

  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Mono origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" rev-list --count main)" -eq 1 ]
  if git -C "$work" remote get-url origin >/dev/null 2>&1; then
    echo "FAIL: non-empty template origin was reused automatically" >&2
    return 1
  fi
  grep -Fq "existing root origin already has Git history and was not reused" \
    "$TMP_ROOT/$name.out"
  grep -Fq "$remote" "$TMP_ROOT/$name.out"
}

run_empty_origin_case() {
  local name="mono-empty-origin"
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
      --desc="Mono empty origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" remote get-url origin)" = "$remote" ]
  grep -Fq "remote: reused existing origin ($remote)" "$TMP_ROOT/$name.out"
}

run_empty_origin_push_without_gh_case() {
  local name="mono-empty-origin-push"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"
  local root_row

  copy_template "$work"
  git init --bare -q "$remote"
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    PATH="/usr/bin:/bin" ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Mono empty origin push test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=yes
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" remote get-url origin)" = "$remote" ]
  git --git-dir="$remote" rev-parse --verify refs/heads/main >/dev/null
  grep -Fq "remote: reused existing origin ($remote)" "$TMP_ROOT/$name.out"
  grep -Fq "pushed: $remote" "$TMP_ROOT/$name.out"

  # A mono project records its one repository's remote on the row whose location is ".", and the
  # check-in flags that row until it does. Nothing else in the suite reads a remote back out of a
  # mono registry -- the multi read-back lives in tests/init-license-validation.sh -- so deleting
  # the write left every case green while every generated mono project reported its own repo as
  # backed up nowhere.
  root_row="$(awk '/^[[:space:]]*-[[:space:]]*name:/ { n++ } n == 1' \
    "$work/Code/$name-docs/registries/repos.yml")"
  printf '%s\n' "$root_row" | grep -Fq 'location: "."' || {
    echo "FAIL: the first registry row is not the workspace root" >&2
    printf '%s\n' "$root_row" >&2
    return 1
  }
  printf '%s\n' "$root_row" | grep -Fq "remote: \"$remote\"" || {
    echo "FAIL: the workspace-root row did not record the remote it pushed to" >&2
    printf '%s\n' "$root_row" >&2
    return 1
  }
  # The recorded URL has to be one the branch reached, and reached at this commit. Asserting the
  # ref exists is not enough: recording happens before the second commit that carries it, so a
  # remote left behind at the initial commit still has a main to find.
  [ "$(git --git-dir="$remote" rev-parse refs/heads/main)" = "$(git -C "$work" rev-parse HEAD)" ] || {
    echo "FAIL: the recorded remote does not hold the local trunk" >&2
    echo "      local $(git -C "$work" rev-parse HEAD) / remote $(git --git-dir="$remote" rev-parse refs/heads/main)" >&2
    return 1
  }
}

run_non_empty_origin_case
run_empty_origin_case
run_empty_origin_push_without_gh_case

echo "init.sh mono origin reuse: PASS"
