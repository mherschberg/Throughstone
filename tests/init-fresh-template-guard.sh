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
#                                              init.sh alone in someone else's repository
#   a clone of the template's own history      history that is not the template's
#                                              a repo tracking files the template does not ship
#   `git init` beside the template, empty      an unborn HEAD with commits on another branch
#                                              an unborn HEAD with files staged, never committed
#   the template's own plain prompts/          a repository of someone else's under prompts/
#   what macOS or Windows leaves in the        a file of someone else's in .github/, tests/,
#   folders setup deletes whole                brand/ or docs/, with or without a .git
#
# The guard carries two lists as literals: the template's root entries, and every file it ships in
# those four folders. Case 12 and the check before case 1 pin them to the template itself so they
# cannot rot. The file list is checked first because a file added to those folders and left off it
# makes every case refuse, and that check is the one that names every such file.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-fresh-guard-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree changes so
# this test covers uncommitted bootstrap edits. The sibling init tests carry copies of it.
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

# assert_refused NAME DIR REASON_TEXT — init must exit 2 and name the check that fired.
assert_refused() {
  local name="$1" dir="$2" reason="$3" rc=0
  init_once "$dir" "$name" --layout=multi >"$TMP_ROOT/$name.out" 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "FAIL: $name — init.sh ran where it should have refused" >&2
    cat "$TMP_ROOT/$name.out" >&2
    exit 1
  fi
  [ "$rc" -eq 2 ] \
    || { echo "FAIL: $name — expected exit 2, got $rc" >&2; cat "$TMP_ROOT/$name.out" >&2; exit 1; }
  grep -Fq "does not look like a fresh Throughstone template checkout" "$TMP_ROOT/$name.out" \
    || { echo "FAIL: $name — refusal did not print the fresh-template message" >&2; cat "$TMP_ROOT/$name.out" >&2; exit 1; }
  grep -Fq "$reason" "$TMP_ROOT/$name.out" \
    || { echo "FAIL: $name — refusal did not name the expected check ('$reason')" >&2; cat "$TMP_ROOT/$name.out" >&2; exit 1; }
}

# assert_history_intact NAME DIR SHA — refusing must leave the user's .git directory, their commit
# SHA and their app.py in place.
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

# --- The guard's list of files in .github/, tests/, brand/ and docs/ matches the template. -------
# Read from a fixture rather than from HEAD: copy_template carries a new, uncommitted file into
# every init fixture, so the guard refuses it until the list names it.
shipped="$TMP_ROOT/shipped"
copy_template "$shipped"
expected="$TMP_ROOT/folder-files-expected"
actual="$TMP_ROOT/folder-files-actual"
( cd "$shipped" && find .github tests brand docs ! -type d ) | LC_ALL=C sort > "$expected"
sed -n "/^TEMPLATE_FOLDER_FILES='\$/,/^'\$/p" "$ROOT/init.sh" | sed '1d;$d' | LC_ALL=C sort > "$actual"
[ -s "$actual" ] || { echo "FAIL: could not read TEMPLATE_FOLDER_FILES out of init.sh" >&2; exit 1; }
diff -u "$expected" "$actual" \
  || { echo "FAIL: init.sh's TEMPLATE_FOLDER_FILES has drifted from the files the template ships in .github/, tests/, brand/ and docs/ (- missing, + stale)" >&2; exit 1; }

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
  || { echo "FAIL: re-run refusal did not name the marker check" >&2; cat "$TMP_ROOT/rerun.out" >&2; exit 1; }
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

# --- 5. init.sh alone, dropped into a repository that is not the template, is refused. --------
# No other template file is here: someone fetched just this script and ran it in their own
# repository. The marker check comes first, so it is the one that refuses.
alone="$TMP_ROOT/alone"
alone_sha="$(seed_user_repo "$alone")"
cp -p "$ROOT/init.sh" "$alone/init.sh"
assert_refused "alone" "$alone" "The root pointers carry no template marker"
assert_history_intact "alone" "$alone" "$alone_sha"

# --- 6. The template unpacked into a repository that already exists is refused. ---------------
# This is the case people actually hit, and the sentinel alone never catches it: the extracted
# template brings AGENTS.md and CLAUDE.md, and the marker with them.
over_repo="$TMP_ROOT/over-repo"
over_sha="$(seed_user_repo "$over_repo")"
copy_template "$over_repo"
assert_refused "over-repo" "$over_repo" "committed history is not Throughstone's"
assert_history_intact "over-repo" "$over_repo" "$over_sha"

# --- 7. …and refused just the same when the template was committed first. ---------------------
# Committing before running a destructive script is the cautious thing to do, and it puts the
# marker into HEAD. What gives it away is that the repository tracks the user's own files too.
committed="$TMP_ROOT/committed"
seed_user_repo "$committed" >/dev/null
copy_template "$committed"
( cd "$committed" && git add -A && seed_commit "add throughstone" )
committed_sha="$(git -C "$committed" rev-parse HEAD)"
assert_refused "committed" "$committed" "which Throughstone does not ship"
assert_history_intact "committed" "$committed" "$committed_sha"

# --- 8. An unborn HEAD inside a live repository is refused. -----------------------------------
# `git checkout --orphan` leaves HEAD unborn and an index the user may well have cleared, but
# every commit is still reachable from the branch they came from.
orphan="$TMP_ROOT/orphan"
orphan_sha="$(seed_user_repo "$orphan")"
( cd "$orphan" && git checkout -q --orphan blank && git rm -rq --cached . )
copy_template "$orphan"
assert_refused "orphan" "$orphan" "branches or tags carrying history"
[ -d "$orphan/.git" ] && git -C "$orphan" cat-file -e "$orphan_sha" 2>/dev/null \
  || { echo "FAIL: orphan — init.sh destroyed history reachable from another branch" >&2; exit 1; }

# --- 9. Files staged but never committed are refused. -----------------------------------------
staged="$TMP_ROOT/staged"
mkdir -p "$staged"
( cd "$staged" && git init -q && printf 'our source\n' > app.py && git add -A )
copy_template "$staged"
assert_refused "staged" "$staged" "staged files that were never committed"
[ -n "$(git -C "$staged" ls-files)" ] \
  || { echo "FAIL: staged — init.sh cleared the user's index before refusing" >&2; exit 1; }

# --- 10. A repository of someone else's under prompts/ is refused. -----------------------------
# The root here is an ordinary unpacked template with no .git, so init.sh's check 1 passes it and
# checks 2-4 do not run. Only check 5 looks at prompts/, which the multi layout makes a repository.
# Without check 5, init_repo would commit into the repository already there and rename its branch,
# and the run would exit 0.
nested="$TMP_ROOT/nested-prompts"
copy_template "$nested"
( cd "$nested/prompts" && git init -q && printf 'my prompt\n' > mine.md && git add -A \
    && seed_commit "prompts I already had" && git branch -M work )
nested_sha="$(git -C "$nested/prompts" rev-parse HEAD)"
if init_once "$nested" nestedprompts --layout=multi >"$TMP_ROOT/nested.out" 2>&1; then
  echo "FAIL: nested-prompts — init.sh committed into a repository that was already there" >&2
  cat "$TMP_ROOT/nested.out" >&2
  exit 1
fi
grep -Fq "does not look like a fresh Throughstone template checkout" "$TMP_ROOT/nested.out" \
  || { echo "FAIL: nested-prompts — refusal did not print the fresh-template message" >&2; cat "$TMP_ROOT/nested.out" >&2; exit 1; }
grep -Fq "prompts/ is already a Git repository" "$TMP_ROOT/nested.out" \
  || { echo "FAIL: nested-prompts — refusal did not name the check that fired" >&2; cat "$TMP_ROOT/nested.out" >&2; exit 1; }
# Refusing has to leave that repository exactly as it was found — same tip commit, same branch,
# same files. A guard that refuses after committing has still done the damage.
[ "$(git -C "$nested/prompts" rev-parse HEAD)" = "$nested_sha" ] \
  || { echo "FAIL: nested-prompts — init.sh added a commit before refusing" >&2; exit 1; }
[ "$(git -C "$nested/prompts" symbolic-ref --short HEAD)" = "work" ] \
  || { echo "FAIL: nested-prompts — init.sh renamed the branch before refusing" >&2; exit 1; }
[ -f "$nested/prompts/mine.md" ] \
  || { echo "FAIL: nested-prompts — init.sh removed files before refusing" >&2; exit 1; }
[ -d "$nested/Code/{{PROJECT}}-docs" ] \
  || { echo "FAIL: nested-prompts — init.sh crossed the destructive boundary before refusing" >&2; exit 1; }

# --- 11. The template's own prompts/ still proceeds (the matching must-proceed case). ----------
# Cases 1, 3 and 4 already carry this pairing, since their prompts/ is a plain directory too;
# assert it here as well, next to the refusal it bounds, because a check written as
# `[ -e prompts ]` would pass every assertion in case 10 and refuse every project.
plain_prompts="$TMP_ROOT/plain-prompts"
copy_template "$plain_prompts"
[ -d "$plain_prompts/prompts" ] && [ ! -e "$plain_prompts/prompts/.git" ] \
  || { echo "FAIL: plain-prompts — fixture is not the shape this case is about" >&2; exit 1; }
init_once "$plain_prompts" plainprompts --layout=multi >"$TMP_ROOT/plain-prompts.out" 2>&1 \
  || { echo "FAIL: guard blocked a template whose prompts/ is a plain directory" >&2; cat "$TMP_ROOT/plain-prompts.out" >&2; exit 1; }
[ -d "$plain_prompts/prompts/.git" ] \
  || { echo "FAIL: plain-prompts — init.sh did not make prompts/ a repository" >&2; exit 1; }

# --- 12. The guard's root-entry list matches what the template actually ships. ------------------
# The list is a literal inside init.sh, so it can rot the moment a root entry is added or removed.
# Derive the truth from the template and compare, so adding one without the other fails here.
expected="$TMP_ROOT/root-entries-expected"
actual="$TMP_ROOT/root-entries-actual"
git -C "$ROOT" ls-tree -z --name-only HEAD | tr '\0' '\n' | sort > "$expected"
sed -n "s/^TEMPLATE_ROOT_ENTRIES='|\(.*\)|'$/\1/p" "$ROOT/init.sh" | tr '|' '\n' | sort > "$actual"
[ -s "$actual" ] || { echo "FAIL: could not read TEMPLATE_ROOT_ENTRIES out of init.sh" >&2; exit 1; }
diff -u "$expected" "$actual" \
  || { echo "FAIL: init.sh's TEMPLATE_ROOT_ENTRIES has drifted from the template's root (- missing, + stale)" >&2; exit 1; }

# --- 13. The template unpacked over a folder of someone else's is refused. ----------------------
# There is no .git, so checks 1-5 pass it. Section 2 deletes .github/, tests/, brand/ and docs/
# whole, and with them every file of the user's in a folder that shares a name with the template's.
# The user's files sit in all four folders, two of them in a subfolder, and one is a dotfile, which
# is the user's like any other.
over_folder="$TMP_ROOT/over-folder"
mkdir -p "$over_folder/.github/workflows" "$over_folder/brand" "$over_folder/docs/api" \
  "$over_folder/tests"
printf 'name: CI\n' > "$over_folder/.github/workflows/ci.yml"
printf '<svg/>\n' > "$over_folder/brand/logo.svg"
printf 'our design\n' > "$over_folder/docs/api/design.md"
printf 'our notes\n' > "$over_folder/docs/.notes.md"
printf 'def test_app(): pass\n' > "$over_folder/tests/test_app.py"
copy_template "$over_folder"
assert_refused "over-folder" "$over_folder" \
  "5 files there are not ones the template ships, among them '.github/workflows/ci.yml'."
[ -f "$over_folder/.github/workflows/ci.yml" ] && [ -f "$over_folder/brand/logo.svg" ] \
  && [ -f "$over_folder/docs/api/design.md" ] && [ -f "$over_folder/docs/.notes.md" ] \
  && [ -f "$over_folder/tests/test_app.py" ] \
  || { echo "FAIL: over-folder — init.sh deleted the user's files before refusing" >&2; exit 1; }
[ -d "$over_folder/Code/{{PROJECT}}-docs" ] \
  || { echo "FAIL: over-folder — init.sh crossed the destructive boundary before refusing" >&2; exit 1; }

# --- 14. …and so is a file someone added to a clone of the template. ---------------------------
# Checks 2 and 3 read the clone's history, and an untracked file is in none of it. Its name,
# tests/links, is a shipped file's (tests/links.sh) cut short, so a guard that matched the list by
# prefix would let it through.
clone_extra="$TMP_ROOT/clone-extra"
git clone -q "$clone_seed" "$clone_extra"
printf 'mine\n' > "$clone_extra/tests/links"
assert_refused "clone-extra" "$clone_extra" "'tests/links' is not a file the template ships."
[ -d "$clone_extra/.git" ] && [ -f "$clone_extra/tests/links" ] \
  || { echo "FAIL: clone-extra — init.sh removed .git or the user's file before refusing" >&2; exit 1; }

# --- 15. What macOS or Windows leaves in those folders still proceeds. -------------------------
# Finder leaves .DS_Store in any folder it shows, macOS writes a ._ file beside each file on a
# volume that cannot hold its extended attributes, Explorer leaves Thumbs.db and desktop.ini, and a
# downloaded file copied from Windows into WSL arrives with a :Zone.Identifier file beside it. None
# of it is the user's work, and refusing it would refuse a template someone only looked through.
# An empty folder holds nothing to lose either.
os_meta="$TMP_ROOT/os-meta"
copy_template "$os_meta"
: > "$os_meta/docs/.DS_Store"
: > "$os_meta/docs/._index.html"
: > "$os_meta/brand/logo/Thumbs.db"
: > "$os_meta/.github/desktop.ini"
: > "$os_meta/tests/links.sh:Zone.Identifier"
mkdir -p "$os_meta/tests/empty"
init_once "$os_meta" osmeta --layout=multi >"$TMP_ROOT/os-meta.out" 2>&1 \
  || { echo "FAIL: guard blocked a template holding only what macOS or Windows leaves in the folders setup deletes" >&2; cat "$TMP_ROOT/os-meta.out" >&2; exit 1; }

echo "init.sh fresh-template guard: PASS"
