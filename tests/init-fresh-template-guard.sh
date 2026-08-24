#!/usr/bin/env bash
#
# Regression coverage for init.sh's fresh-template guard.
#
# init.sh is a one-time, destructive bootstrap: it removes .git and every template-only file. Run
# anywhere other than a freshly downloaded template that destroys whatever is there — most
# seriously, unpacking the template into a repository that already exists and running it in place
# deletes that repository's history outright.
#
# The guard refuses before the destructive boundary. It has to refuse without over-refusing, so
# every refusing case below is paired with a case that must still proceed:
#
#   proceeds                                   refuses
#   --------                                   -------
#   a fresh unpacked template (no .git)        an already-initialized project (no sentinel)
#   a clone of the template's own history      history that is not the template's
#   `git init` beside the template, empty      a repo tracking files the template does not ship
#                                              an unborn HEAD with commits on another branch
#                                              an unborn HEAD with files staged, never committed
#
# The last check pins the template's root-entry list, which the guard carries as a literal, to the
# template itself so it cannot rot.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-fresh-guard-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree changes so
# this test covers uncommitted bootstrap edits (same helper as the sibling init tests).
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

seed_commit() { git -c user.name="Throughstone Test" -c user.email="throughstone-test@example.invalid" commit -qm "$1"; }

init_once() { # DIR SLUG EXTRA_ARGS...
  local dir="$1" slug="$2"; shift 2
  ( cd "$dir" && ./init.sh \
      --non-interactive --slug="$slug" --desc="Guard test" \
      --license=private --collab=solo --remotes=no "$@" )
}

# assert_refused NAME DIR REASON_TEXT — init must exit non-zero and name the check that fired.
assert_refused() {
  local name="$1" dir="$2" reason="$3"
  if init_once "$dir" "$name" --layout=multi >"$TMP_ROOT/$name.out" 2>&1; then
    echo "FAIL: $name — init.sh ran where it should have refused" >&2
    cat "$TMP_ROOT/$name.out" >&2
    exit 1
  fi
  grep -Fq "does not look like a fresh Throughstone template checkout" "$TMP_ROOT/$name.out" \
    || { echo "FAIL: $name — refusal did not print the fresh-template message" >&2; cat "$TMP_ROOT/$name.out" >&2; exit 1; }
  grep -Fq "$reason" "$TMP_ROOT/$name.out" \
    || { echo "FAIL: $name — refusal did not name the expected check ('$reason')" >&2; cat "$TMP_ROOT/$name.out" >&2; exit 1; }
}

# assert_history_intact NAME DIR SHA — refusing must leave the user's repository exactly as found.
assert_history_intact() {
  local name="$1" dir="$2" sha="$3"
  [ -d "$dir/.git" ] \
    || { echo "FAIL: $name — init.sh deleted .git before refusing" >&2; exit 1; }
  git -C "$dir" cat-file -e "$sha" 2>/dev/null \
    || { echo "FAIL: $name — init.sh destroyed the user's commit $sha before refusing" >&2; exit 1; }
  [ -f "$dir/app.py" ] \
    || { echo "FAIL: $name — init.sh removed the user's files before refusing" >&2; exit 1; }
}

# seed_user_repo DIR — a repository with history of its own, as a user would have before they ever
# heard of Throughstone. Echoes the commit that must survive.
seed_user_repo() {
  local dir="$1"
  mkdir -p "$dir"
  ( cd "$dir" && git init -q && printf 'our source\n' > app.py && git add -A && seed_commit "five years of history" )
  git -C "$dir" rev-parse HEAD
}

# --- 1. A fresh template initializes normally (the guard must not over-fire). -----------------
fresh="$TMP_ROOT/fresh"
copy_template "$fresh"
init_once "$fresh" acme --layout=mono >"$TMP_ROOT/fresh.out" 2>&1 \
  || { echo "FAIL: guard blocked a fresh template checkout" >&2; cat "$TMP_ROOT/fresh.out" >&2; exit 1; }
commits_before="$(git -C "$fresh" rev-list --count HEAD 2>/dev/null || echo 0)"
[ "$commits_before" -ge 1 ] || { echo "FAIL: fresh init did not create a mono repo" >&2; exit 1; }

# --- 2. Re-running init in that initialized project is refused, non-destructively. ------------
if init_once "$fresh" acme --layout=mono >"$TMP_ROOT/rerun.out" 2>&1; then
  echo "FAIL: init.sh re-ran inside an already-initialized project" >&2
  cat "$TMP_ROOT/rerun.out" >&2
  exit 1
fi
grep -Fq "The root pointers carry no template marker" "$TMP_ROOT/rerun.out" \
  || { echo "FAIL: re-run refusal did not print the fresh-template message" >&2; cat "$TMP_ROOT/rerun.out" >&2; exit 1; }
commits_after="$(git -C "$fresh" rev-list --count HEAD 2>/dev/null || echo 0)"
[ "$commits_after" = "$commits_before" ] \
  || { echo "FAIL: re-run destroyed the generated repo's history ($commits_before -> $commits_after)" >&2; exit 1; }
[ -d "$fresh/Code/acme-docs" ] || { echo "FAIL: re-run mutated the initialized project" >&2; exit 1; }

# --- 3. A clone of the template's own history proceeds. ---------------------------------------
# The documented Quickstart clones this repo, and "Use this template" produces a repo whose single
# commit is the unmodified template. Both arrive with committed history, and both are fresh.
clone_seed="$TMP_ROOT/clone-seed"
copy_template "$clone_seed"
( cd "$clone_seed" && git init -q && git add -A && seed_commit "Template-created commit" && git branch -M main )
git clone -q "$clone_seed" "$TMP_ROOT/cloned"
init_once "$TMP_ROOT/cloned" cloned --layout=multi >"$TMP_ROOT/cloned.out" 2>&1 \
  || { echo "FAIL: guard blocked a clone of the template's own history" >&2; cat "$TMP_ROOT/cloned.out" >&2; exit 1; }

# --- 4. `git init` beside an unpacked template proceeds. --------------------------------------
# Attaching an empty origin before bootstrap is supported (see tests/init-mono-origin-reuse.sh):
# an unborn HEAD with no refs and nothing staged has nothing to lose.
empty_repo="$TMP_ROOT/empty-repo"
copy_template "$empty_repo"
( cd "$empty_repo" && git init -q )
init_once "$empty_repo" emptyrepo --layout=multi >"$TMP_ROOT/empty-repo.out" 2>&1 \
  || { echo "FAIL: guard blocked an empty repo attached to a fresh template" >&2; cat "$TMP_ROOT/empty-repo.out" >&2; exit 1; }

# --- 5. The template unpacked into a repository that already exists is refused. ---------------
# This is the case people actually hit, and the sentinel alone never catches it: the extracted
# template brings AGENTS.md and CLAUDE.md, and the marker with them.
over_repo="$TMP_ROOT/over-repo"
over_sha="$(seed_user_repo "$over_repo")"
copy_template "$over_repo"
assert_refused "over-repo" "$over_repo" "committed history is not Throughstone's"
assert_history_intact "over-repo" "$over_repo" "$over_sha"

# --- 6. …and refused just the same when the template was committed first. ---------------------
# Committing before running a destructive script is the cautious thing to do, and it puts the
# marker into HEAD. What gives it away is that the repository tracks the user's own files too.
committed="$TMP_ROOT/committed"
seed_user_repo "$committed" >/dev/null
copy_template "$committed"
( cd "$committed" && git add -A && seed_commit "add throughstone" )
committed_sha="$(git -C "$committed" rev-parse HEAD)"
assert_refused "committed" "$committed" "which Throughstone does not ship"
assert_history_intact "committed" "$committed" "$committed_sha"

# --- 7. An unborn HEAD inside a live repository is refused. -----------------------------------
# `git checkout --orphan` leaves no HEAD and an index the user may well have cleared, but every
# commit is still reachable from the branch they came from.
orphan="$TMP_ROOT/orphan"
orphan_sha="$(seed_user_repo "$orphan")"
( cd "$orphan" && git checkout -q --orphan blank && git rm -rq --cached . )
copy_template "$orphan"
assert_refused "orphan" "$orphan" "branches or tags carrying history"
[ -d "$orphan/.git" ] && git -C "$orphan" cat-file -e "$orphan_sha" 2>/dev/null \
  || { echo "FAIL: orphan — init.sh destroyed history reachable from another branch" >&2; exit 1; }

# --- 8. Files staged but never committed are refused. -----------------------------------------
staged="$TMP_ROOT/staged"
mkdir -p "$staged"
( cd "$staged" && git init -q && printf 'our source\n' > app.py && git add -A )
copy_template "$staged"
assert_refused "staged" "$staged" "staged files that were never committed"
[ -n "$(git -C "$staged" ls-files)" ] \
  || { echo "FAIL: staged — init.sh cleared the user's index before refusing" >&2; exit 1; }

# --- 9. The guard's root-entry list matches what the template actually ships. ------------------
# The list is a literal inside init.sh, so it can rot the moment a root entry is added or removed.
# Derive the truth from the template and compare, so adding one without the other fails here.
expected="$TMP_ROOT/root-entries-expected"
actual="$TMP_ROOT/root-entries-actual"
git -C "$ROOT" ls-tree -z --name-only HEAD | tr '\0' '\n' | sort > "$expected"
sed -n "s/^TEMPLATE_ROOT_ENTRIES='|\(.*\)|'$/\1/p" "$ROOT/init.sh" | tr '|' '\n' | sort > "$actual"
[ -s "$actual" ] || { echo "FAIL: could not read TEMPLATE_ROOT_ENTRIES out of init.sh" >&2; exit 1; }
diff -u "$expected" "$actual" \
  || { echo "FAIL: init.sh's TEMPLATE_ROOT_ENTRIES has drifted from the template's root (- missing, + stale)" >&2; exit 1; }

echo "init.sh fresh-template guard: PASS"
