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
init_once "$fresh" --mode=existing --layout=mono --registries=yes >"$TMP_ROOT/fresh.out" 2>&1 \
  || { echo "FAIL: guard blocked a fresh template checkout" >&2; cat "$TMP_ROOT/fresh.out" >&2; exit 1; }
commits_before="$(git -C "$fresh" rev-list --count HEAD 2>/dev/null || echo 0)"
[ "$commits_before" -ge 1 ] || { echo "FAIL: fresh init did not create a mono repo" >&2; exit 1; }

# --- 2. Re-running init in that initialized project is refused, non-destructively. ------------
if init_once "$fresh" --mode=existing --layout=mono --registries=yes >"$TMP_ROOT/rerun.out" 2>&1; then
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
if init_once "$unrelated" --mode=new --layout=mono --registries=yes >"$TMP_ROOT/unrelated.out" 2>&1; then
  echo "FAIL: init.sh ran on top of an unrelated repo" >&2
  cat "$TMP_ROOT/unrelated.out" >&2
  exit 1
fi
[ -d "$unrelated/.git" ] && [ "$(git -C "$unrelated" rev-parse HEAD)" = "$unrelated_commit" ] \
  || { echo "FAIL: init.sh damaged an unrelated repo before refusing" >&2; exit 1; }
[ -f "$unrelated/keep.txt" ] || { echo "FAIL: init.sh removed unrelated files before refusing" >&2; exit 1; }

echo "init.sh fresh-template guard: PASS"
