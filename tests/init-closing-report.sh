#!/usr/bin/env bash
#
# Regression coverage for what init.sh reports about the repositories it made: the per-repo lines,
# and an ending chosen by what the run did — the general backup-setup section only when no remote
# was asked for, a statement that the project was pushed when a backup completed, and neither when
# one failed.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-closing-report-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

STUB_BIN="$TMP_ROOT/stub-bin"
mkdir -p "$STUB_BIN"
cp "$ROOT/tests/fixtures/gh-stub.sh" "$STUB_BIN/gh"
chmod +x "$STUB_BIN/gh"

FAILED=0

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

bare_remote() {
  git init --bare -q -b main "$1"
}

# refusing_remote PATH - a bare remote that rejects every push.
refusing_remote() {
  bare_remote "$1"
  printf '#!/bin/sh\nexit 1\n' >"$1/hooks/pre-receive"
  chmod +x "$1/hooks/pre-receive"
}

fail() {
  echo "FAIL: $CASE — $*" >&2
  FAILED=1
}

# run_init WORK ARGS... - run init.sh inside WORK with the gh stub on PATH, capturing both streams
# in $OUT and the exit status in $STATUS. Everything from the "Done" line on goes to $END.
run_init() {
  local work="$1"; shift
  OUT="$TMP_ROOT/$CASE.out"; END="$TMP_ROOT/$CASE.end"
  GH_REMOTE_ROOT="$TMP_ROOT/$CASE-gh-remotes"
  mkdir -p "$GH_REMOTE_ROOT"
  set +e
  ( cd "$work" && PATH="$STUB_BIN:$PATH" GH_LOG="$TMP_ROOT/$CASE-gh.log" \
      GH_REMOTE_ROOT="$GH_REMOTE_ROOT" ./init.sh "$@" ) >"$OUT" 2>&1 </dev/null
  STATUS=$?
  set -e
  awk '/Done\.|Done — / { f = 1 } f' "$OUT" > "$END"
  [ -s "$END" ] || fail "no Done line in the output"
}

expect_status() {
  [ "$STATUS" -eq "$1" ] || { fail "expected exit $1, got $STATUS"; cat "$OUT" >&2; }
}

# expect_line TEXT FILE - FILE has a line that is exactly TEXT.
expect_line() {
  grep -Fxq -- "$1" "$2" || fail "expected the line '$1' in $(basename "$2")"
}

expect_in() {
  grep -Fq -- "$1" "$2" || fail "expected '$1' in $(basename "$2")"
}

expect_not_in() {
  if grep -Fq -- "$1" "$2"; then fail "did not expect '$1' in $(basename "$2")"; fi
}

# expect_no_setup_advice - the ending does not include the general backup-setup section.
expect_no_setup_advice() {
  expect_not_in "Recommended optional backup" "$END"
  expect_not_in "To back up" "$END"
  expect_not_in "put the project on a Git host" "$END"
  expect_not_in "https://github.com/" "$END"
}

BASE=(--non-interactive --collab=solo --desc="Closing report")

# --- No backup asked for ------------------------------------------------------------------------

# Mono with no origin. A trunk other than main shows the branch in the report is the run's own.
CASE=mono-none
W="$TMP_ROOT/$CASE"; copy_template "$W"
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=mit --holder="Closing Test" \
  --layout=mono --remotes=no --trunk-branch=trunk
expect_status 0
expect_line "  git repo: . (initial commit on trunk)" "$OUT"
[ "$(git -C "$W" rev-list --count trunk 2>/dev/null)" = "1" ] || fail "the reported commit is not on trunk"
expect_line "  license: ./LICENSE (this repository's license)" "$OUT"
expect_line "  license: Code/$CASE-docs/LICENSE (the canonical copy, same text, which apply-project-license.sh gives new code repos)" "$OUT"
[ -z "$(git -C "$W" remote)" ] || fail "the run attached a remote, so the case does not test what it says"
expect_line "Recommended optional backup:" "$END"
expect_line "  No remote is attached. To back up, create one empty repo on your host, attach it" "$END"
expect_in "push the root repo's trunk branch to it." "$END"
expect_in "registries/repos.yml whose" "$END"
expect_not_in "existing origin is kept" "$END"
expect_not_in "Saved:" "$END"
expect_not_in "also pushed" "$END"
# Nothing after this run can create a GitHub remote, so the ending does not offer gh for it.
expect_not_in "GitHub CLI" "$END"

# Mono keeping the folder's empty origin: the ending names it, says nothing went to it, and gives
# the push for this run's trunk.
CASE=mono-kept-origin
W="$TMP_ROOT/$CASE"; copy_template "$W"
REMOTE="$TMP_ROOT/$CASE-origin.git"; bare_remote "$REMOTE"
( cd "$W" && git init -q && git remote add origin "$REMOTE" )
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=mono --remotes=no \
  --trunk-branch=release
expect_status 0
[ -z "$(git --git-dir="$REMOTE" for-each-ref)" ] || fail "the kept origin received a push"
expect_line "Recommended optional backup:" "$END"
expect_line "  This folder's existing origin is kept as the project's remote, and nothing was" "$END"
expect_line "    $REMOTE" "$END"
expect_line "  To back up, push the root repo's release branch to it: git push -u origin release" "$END"
expect_line "  Then record that URL on the row in Code/$CASE-docs/registries/repos.yml whose" "$END"
expect_not_in "No remote is attached" "$END"
expect_not_in "also pushed" "$END"

# Mono with an origin that already has history: it is not reused, so the ending must not describe
# it as kept.
CASE=mono-unused-origin
W="$TMP_ROOT/$CASE"; copy_template "$W"
REMOTE="$TMP_ROOT/$CASE-origin.git"; bare_remote "$REMOTE"
SEED="$TMP_ROOT/$CASE-seed"
git init -q -b main "$SEED"
git -C "$SEED" -c user.name="Throughstone Test" -c user.email="throughstone-test@example.invalid" \
  commit -q --allow-empty -m "Existing history"
git -C "$SEED" push -q "$REMOTE" main
( cd "$W" && git init -q && git remote add origin "$REMOTE" )
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=mono --remotes=no
expect_status 0
expect_in "already has Git history and was not reused" "$OUT"
[ -z "$(git -C "$W" remote)" ] || fail "the run attached a remote, so the case does not test what it says"
expect_line "  No remote is attached. To back up, create one empty repo on your host, attach it" "$END"
expect_not_in "existing origin is kept" "$END"

# Multi: the advice covers both repos, and names the run's trunk.
CASE=multi-none
W="$TMP_ROOT/$CASE"; copy_template "$W"
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=multi --remotes=no \
  --trunk-branch=develop
expect_status 0
expect_line "  git repo: Code/$CASE-docs (initial commit on develop)" "$OUT"
expect_line "  git repo: prompts (initial commit on develop)" "$OUT"
expect_line "Recommended optional backup:" "$END"
expect_line "  No remote was set up for either repo. To back up, do this for each of the two," "$END"
expect_in "push the develop branch to it" "$END"
expect_not_in "No remote is attached" "$END"
expect_not_in "Saved:" "$END"
expect_not_in "also pushed" "$END"

# --- Backup asked for and completed -------------------------------------------------------------

CASE=mono-pushed
W="$TMP_ROOT/$CASE"; copy_template "$W"
REMOTE="$TMP_ROOT/$CASE-remote.git"; bare_remote "$REMOTE"
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=mono \
  --remotes=yes --remote-provider=manual --remote-url="$REMOTE"
expect_status 0
[ "$(git --git-dir="$REMOTE" rev-parse refs/heads/main 2>/dev/null)" = "$(git -C "$W" rev-parse HEAD)" ] \
  || fail "the remote does not hold the local trunk, so the ending's claim is untested"
expect_line "Saved:" "$END"
expect_in "your project is committed locally with Git" "$END"
expect_line "  It is also pushed to the remote named above." "$END"
expect_no_setup_advice

# Public, not the default, so the visibility in the report is the one the run used.
CASE=multi-github
W="$TMP_ROOT/$CASE"; copy_template "$W"
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=mit --holder="Closing Test" --layout=multi \
  --remotes=yes --remote-provider=github --owner=closing-test --visibility=public
expect_status 0
for repo in "$CASE-docs" "$CASE-prompts"; do
  expect_line "  remote: created closing-test/$repo on GitHub (public)" "$OUT"
  expect_line "  pushed: $GH_REMOTE_ROOT/$repo.git" "$OUT"
done
# Each multi repo's LICENSE is its own; the mono two-copy explanation does not apply.
expect_line "  license: Code/$CASE-docs/LICENSE" "$OUT"
expect_line "  license: prompts/LICENSE" "$OUT"
expect_not_in "canonical copy" "$OUT"
expect_line "Saved:" "$END"
expect_in "both repositories here are committed locally with Git" "$END"
expect_line "  Both are also pushed to the remotes named above." "$END"
expect_no_setup_advice

# --- Backup asked for and not completed ---------------------------------------------------------

# The docs push succeeds and the prompts push is refused: the report after the ending is the next
# action, so the ending neither prints the general setup section nor says the backup happened.
CASE=multi-failed
W="$TMP_ROOT/$CASE"; copy_template "$W"
bare_remote "$TMP_ROOT/$CASE-docs.git"
refusing_remote "$TMP_ROOT/$CASE-prompts.git"
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=multi \
  --remotes=yes --remote-provider=manual \
  --docs-remote="$TMP_ROOT/$CASE-docs.git" --prompts-remote="$TMP_ROOT/$CASE-prompts.git"
expect_status 1
expect_line "Saved:" "$END"
expect_in "both repositories here are committed locally with Git" "$END"
expect_not_in "also pushed" "$END"
expect_no_setup_advice
expect_in "The remote backup did not complete for: $CASE-prompts" "$END"

# The same through the mono layout: the folder's empty origin is kept and refuses the push.
CASE=mono-failed
W="$TMP_ROOT/$CASE"; copy_template "$W"
REMOTE="$TMP_ROOT/$CASE-origin.git"; refusing_remote "$REMOTE"
( cd "$W" && git init -q && git remote add origin "$REMOTE" )
run_init "$W" "${BASE[@]}" --slug="$CASE" --license=proprietary --layout=mono --remotes=yes
expect_status 1
expect_line "Saved:" "$END"
expect_in "your project is committed locally with Git" "$END"
expect_not_in "also pushed" "$END"
expect_not_in "existing origin is kept" "$END"
expect_no_setup_advice
expect_in "The remote backup did not complete for: $CASE" "$END"

if [ "$FAILED" != "0" ]; then
  exit 1
fi
echo "init.sh closing report: PASS"
