#!/usr/bin/env bash
#
# Regression coverage for init.sh's fresh-template guard.
#
# init.sh is a one-time, destructive bootstrap (it removes .git and template-only files). It must
# refuse to run unless it is a fresh template checkout — detected by the THROUGHSTONE-TEMPLATE-GUARD
# sentinel in the root pointers, which init strips during setup. This catches two footguns:
#   - re-running init inside an already-initialized project (a mono re-run would delete the
#     generated repo's history, then fail partway through);
#   - running init on top of an unrelated repo.
# Both must be refused BEFORE the destructive boundary, leaving any existing history intact.

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

init_once() { # DIR EXTRA_ARGS...
  local dir="$1"; shift
  ( cd "$dir" && ./init.sh \
      --non-interactive --slug=acme --desc="Guard test" \
      --license=private --collab=solo --remotes=no "$@" )
}

# --- 1. A fresh template initializes normally (the guard must not over-fire). -----------------
fresh="$TMP_ROOT/fresh"
copy_template "$fresh"
init_once "$fresh" --layout=mono --registries=yes >"$TMP_ROOT/fresh.out" 2>&1 \
  || { echo "FAIL: guard blocked a fresh template checkout" >&2; cat "$TMP_ROOT/fresh.out" >&2; exit 1; }
commits_before="$(git -C "$fresh" rev-list --count HEAD 2>/dev/null || echo 0)"
[ "$commits_before" -ge 1 ] || { echo "FAIL: fresh init did not create a mono repo" >&2; exit 1; }

# --- 2. Re-running init in that initialized project is refused, non-destructively. ------------
if init_once "$fresh" --layout=mono --registries=yes >"$TMP_ROOT/rerun.out" 2>&1; then
  echo "FAIL: init.sh re-ran inside an already-initialized project" >&2
  cat "$TMP_ROOT/rerun.out" >&2
  exit 1
fi
grep -Fq "does not look like a fresh Throughstone template checkout" "$TMP_ROOT/rerun.out" \
  || { echo "FAIL: re-run refusal did not print the fresh-template message" >&2; cat "$TMP_ROOT/rerun.out" >&2; exit 1; }
commits_after="$(git -C "$fresh" rev-list --count HEAD 2>/dev/null || echo 0)"
[ "$commits_after" = "$commits_before" ] \
  || { echo "FAIL: re-run destroyed the generated repo's history ($commits_before -> $commits_after)" >&2; exit 1; }
[ -d "$fresh/Code/acme-docs" ] || { echo "FAIL: re-run mutated the initialized project" >&2; exit 1; }

# --- 3. Running init on top of an unrelated repo (no sentinel) is refused before destruction. --
unrelated="$TMP_ROOT/unrelated"
mkdir -p "$unrelated"
cp -p "$ROOT/init.sh" "$unrelated/init.sh"
( cd "$unrelated" && git init -q && printf 'hi\n' > keep.txt && git add -A \
    && git -c user.name=t -c user.email=t@e commit -qm "pre-existing" )
unrelated_commit="$(git -C "$unrelated" rev-parse HEAD)"
if init_once "$unrelated" --layout=mono --registries=yes >"$TMP_ROOT/unrelated.out" 2>&1; then
  echo "FAIL: init.sh ran on top of an unrelated repo" >&2
  cat "$TMP_ROOT/unrelated.out" >&2
  exit 1
fi
[ -d "$unrelated/.git" ] && [ "$(git -C "$unrelated" rev-parse HEAD)" = "$unrelated_commit" ] \
  || { echo "FAIL: init.sh damaged an unrelated repo before refusing" >&2; exit 1; }
[ -f "$unrelated/keep.txt" ] || { echo "FAIL: init.sh removed unrelated files before refusing" >&2; exit 1; }

# --- 4. The WHOLE template extracted into an existing repo is refused. ------------------------
# Case 3 drops init.sh alone, so there is no AGENTS.md and the sentinel check catches it. The
# mistake people actually make is extracting the whole download into their repo — and then the
# sentinel is present, says "fresh", and the destructive step removes THEIR .git. METHOD.md §7
# lets a repo be registered in place, so a user who already has one has every reason to be holding
# the template near it. Mono layout is the worst shape (it re-inits and writes a project LICENSE
# plus a LICENSING.md asserting it over their code), so test that one.
extracted="$TMP_ROOT/extracted"
mkdir -p "$extracted"
( cd "$extracted" && git init -q && printf 'GPLv2 terms\n' > COPYING && printf 'ours\n' > src.txt \
    && git add -A && git -c user.name=t -c user.email=t@e commit -qm "existing codebase" )
extracted_commit="$(git -C "$extracted" rev-parse HEAD)"
copy_template "$extracted"          # the download, unpacked on top of their repo
if init_once "$extracted" --layout=mono --registries=yes >"$TMP_ROOT/extracted.out" 2>&1; then
  echo "FAIL: init.sh ran inside an existing repo with the template extracted into it" >&2
  cat "$TMP_ROOT/extracted.out" >&2
  exit 1
fi
grep -Fq "sitting inside an existing Git repository" "$TMP_ROOT/extracted.out" \
  || { echo "FAIL: refusal did not name the reason" >&2; cat "$TMP_ROOT/extracted.out" >&2; exit 1; }
[ "$(git -C "$extracted" rev-parse HEAD)" = "$extracted_commit" ] \
  || { echo "FAIL: init.sh destroyed the existing repo's history before refusing" >&2; exit 1; }
# Nothing written. Assert on paths only init creates — Code/ and prompts/ ship with the template,
# so the extraction alone leaves them and testing those would pass no matter what init did.
for must_be_absent in LICENSING.md .throughstone Code/acme-docs; do
  [ ! -e "$extracted/$must_be_absent" ] \
    || { echo "FAIL: init.sh wrote $must_be_absent into an existing repo before refusing" >&2; exit 1; }
done
[ -d "$extracted/Code/{{PROJECT}}-docs" ] \
  || { echo "FAIL: init.sh renamed the template docs hub before refusing" >&2; exit 1; }
grep -Fxq "GPLv2 terms" "$extracted/COPYING" \
  || { echo "FAIL: init.sh disturbed the existing repo's own licensing file" >&2; exit 1; }

# --- 5. A template that is its own checkout still initializes (the guard must not over-fire). --
# Clone or download, the template may itself be a work tree. What separates it from case 4 is the
# INDEX: its own AGENTS.md is tracked, sentinel and all. Without this case the fix in 4 could be
# written as "refuse inside any work tree", which would break every cloned template.
checkout="$TMP_ROOT/checkout"
copy_template "$checkout"
( cd "$checkout" && git init -q && git add -A \
    && git -c user.name=t -c user.email=t@e commit -qm "throughstone template" )
init_once "$checkout" --layout=multi --registries=yes >"$TMP_ROOT/checkout.out" 2>&1 \
  || { echo "FAIL: guard blocked a template that is its own git checkout" >&2; cat "$TMP_ROOT/checkout.out" >&2; exit 1; }
[ -d "$checkout/Code/acme-docs" ] || { echo "FAIL: template checkout did not initialize" >&2; exit 1; }

# --- 5b. `git init` + an empty origin, nothing committed, still initializes. ------------------
# The mono-repo origin-reuse flow (section 4 of init.sh): the user creates an empty repo on their
# host, runs `git init` in the template folder and points origin at it, then initializes. That is a
# work tree with no commits and an untracked AGENTS.md — indistinguishable from case 4 by tracking,
# and completely different by history. Guarding on "is AGENTS.md tracked" breaks this flow; guarding
# on HEAD does not, which is why the guard reads HEAD.
empty_origin="$TMP_ROOT/empty-origin"
copy_template "$empty_origin"
( cd "$empty_origin" && git init -q && git remote add origin "$TMP_ROOT/empty-origin.git" )
git init --bare -q "$TMP_ROOT/empty-origin.git"
init_once "$empty_origin" --layout=mono --registries=yes >"$TMP_ROOT/empty-origin.out" 2>&1 \
  || { echo "FAIL: guard blocked the empty-root-origin reuse flow" >&2; cat "$TMP_ROOT/empty-origin.out" >&2; exit 1; }
[ -d "$empty_origin/Code/acme-docs" ] || { echo "FAIL: empty-origin flow did not initialize" >&2; exit 1; }

# --- 6. A repo that tracks an AGENTS.md of its own is still refused. --------------------------
# The sentinel must be read from the index, not the working file the extraction just overwrote.
# Testing the working file would pass here and delete their history.
shadowed="$TMP_ROOT/shadowed"
mkdir -p "$shadowed"
( cd "$shadowed" && git init -q && printf 'our own agent notes\n' > AGENTS.md \
    && git add -A && git -c user.name=t -c user.email=t@e commit -qm "existing codebase" )
shadowed_commit="$(git -C "$shadowed" rev-parse HEAD)"
copy_template "$shadowed"
if init_once "$shadowed" --layout=mono --registries=yes >"$TMP_ROOT/shadowed.out" 2>&1; then
  echo "FAIL: init.sh ran inside a repo carrying its own tracked AGENTS.md" >&2
  exit 1
fi
[ "$(git -C "$shadowed" rev-parse HEAD)" = "$shadowed_commit" ] \
  || { echo "FAIL: init.sh destroyed history in the shadowed-AGENTS.md case" >&2; exit 1; }

echo "init.sh fresh-template guard: PASS"
