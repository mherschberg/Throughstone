#!/usr/bin/env bash
#
# Regression coverage for what init.sh checks, and says, before its destructive boundary: a gh that
# cannot create the repositories, the same URL for two repos, free text that cannot be written into
# the generated files, a reused origin, a proprietary push to a repository setup did not create, and
# files a mono project's first commit would take in. A refusal must leave the template untouched.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-pre-boundary-test.XXXXXX")"
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

# path_without_gh - echo a PATH with everything the current one has except gh. Resetting PATH to
# /usr/bin:/bin would leave gh visible wherever it is installed there, as on a GitHub runner.
path_without_gh() {
  local mirror="$TMP_ROOT/no-gh-bin" dir
  rm -rf "$mirror"
  mkdir -p "$mirror"
  local IFS=:
  for dir in $PATH; do
    unset IFS
    [ -d "$dir" ] && ln -s "$dir"/* "$mirror/" 2>/dev/null
    IFS=:
  done
  unset IFS
  rm -f "$mirror/gh"
  printf '%s\n' "$mirror"
}

# caution_names URL - the proprietary caution, not some other line, lists URL.
caution_names() {
  grep -A3 -F "note: this project is proprietary" "$PRE" | grep -Fxq -- "        $1" \
    || fail "the caution did not name $1"
}

fail() {
  echo "FAIL: $CASE — $*" >&2
  FAILED=1
}

# run_init WORK ARGS... - run init.sh inside WORK with the gh stub on PATH, capturing both streams
# in $OUT and the exit status in $STATUS. Everything printed before the boundary goes to $PRE.
# UNREACHABLE=1 before the call makes the stub fail as gh does with no connection; RUN_PATH=...
# replaces the PATH the run sees.
run_init() {
  local work="$1"; shift
  OUT="$TMP_ROOT/$CASE.out"; PRE="$TMP_ROOT/$CASE.pre"
  GH_LOG="$TMP_ROOT/$CASE-gh.log"; GH_REMOTE_ROOT="$TMP_ROOT/$CASE-gh-remotes"
  : > "$GH_LOG"; mkdir -p "$GH_REMOTE_ROOT"
  set +e
  ( cd "$work" && PATH="${RUN_PATH:-$STUB_BIN:$PATH}" GH_LOG="$GH_LOG" GH_REMOTE_ROOT="$GH_REMOTE_ROOT" \
      GH_STUB_UNREACHABLE="${UNREACHABLE:-}" ./init.sh "$@" ) >"$OUT" 2>&1 </dev/null
  STATUS=$?
  set -e
  sed -n '1,/Detaching from the template/p' "$OUT" > "$PRE"
}

# expect_refused WORK TEXT - the run exited 2, said TEXT, and changed nothing.
expect_refused() {
  local work="$1" text="$2"
  [ "$STATUS" -eq 2 ] || fail "expected exit 2, got $STATUS"
  grep -Fq -- "$text" "$OUT" || fail "expected '$text' in the output"
  if [ ! -f "$work/README.md" ] || [ ! -d "$work/Code/{{PROJECT}}-docs" ] || [ ! -d "$work/tests" ]; then
    fail "the template was changed before the refusal"
  fi
  if grep -Fq "Detaching from the template" "$OUT"; then
    fail "the run crossed the boundary"
  fi
}

expect_finished() {
  [ "$STATUS" -eq 0 ] || { fail "expected exit 0, got $STATUS"; cat "$OUT" >&2; }
}

expect_pre() {
  grep -Fq -- "$1" "$PRE" || fail "expected '$1' before the boundary"
}

expect_not_in() {
  if grep -Fq -- "$1" "$2"; then fail "did not expect '$1' in $(basename "$2")"; fi
}

BASE=(--non-interactive --collab=solo)

# --- gh must be able to create the repositories ------------------------------------------------

CASE=gh-unreachable
W="$TMP_ROOT/$CASE"; copy_template "$W"
UNREACHABLE=1 run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" \
  --license=proprietary --layout=multi --remotes=yes --owner=throughstone-test
expect_refused "$W" "the gh CLI could not reach GitHub as a signed-in user"
expect_not_in "repo create" "$GH_LOG"

# The second name, so the check is known to cover every repository and not only the first.
CASE=gh-repo-exists-multi
W="$TMP_ROOT/$CASE"; copy_template "$W"
mkdir -p "$TMP_ROOT/$CASE-gh-remotes"; bare_remote "$TMP_ROOT/$CASE-gh-remotes/$CASE-prompts.git"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" \
  --license=proprietary --layout=multi --remotes=yes --owner=throughstone-test
expect_refused "$W" "throughstone-test/$CASE-prompts already exists on GitHub"
expect_not_in "repo create" "$GH_LOG"

CASE=gh-repo-exists-mono
W="$TMP_ROOT/$CASE"; copy_template "$W"
mkdir -p "$TMP_ROOT/$CASE-gh-remotes"; bare_remote "$TMP_ROOT/$CASE-gh-remotes/$CASE.git"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" \
  --license=proprietary --layout=mono --remotes=yes --owner=throughstone-test
expect_refused "$W" "throughstone-test/$CASE already exists on GitHub"
expect_not_in "repo create" "$GH_LOG"

# Must proceed: a usable gh, and both lookups happen before anything is created.
CASE=gh-ready
W="$TMP_ROOT/$CASE"; copy_template "$W"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" \
  --license=proprietary --layout=multi --remotes=yes --owner=throughstone-test
expect_finished
printf 'api user --silent\nrepo view throughstone-test/%s-docs --json name\nrepo view throughstone-test/%s-prompts --json name\n' \
  "$CASE" "$CASE" > "$TMP_ROOT/$CASE-gh.expected"
head -n 3 "$GH_LOG" | cmp -s - "$TMP_ROOT/$CASE-gh.expected" \
  || { fail "gh was not checked before creating"; cat "$GH_LOG" >&2; }
[ "$(grep -c '^repo create' "$GH_LOG")" -eq 2 ] || fail "expected two repositories created"
# The run creates these repositories and knows their visibility, so there is nothing to caution.
expect_not_in "this project is proprietary" "$OUT"

# --- the same URL for both repos --------------------------------------------------------------

CASE=duplicate-url
W="$TMP_ROOT/$CASE"; copy_template "$W"
bare_remote "$TMP_ROOT/$CASE-remote.git"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=proprietary --layout=multi \
  --remotes=yes --remote-provider=manual \
  --docs-remote="$TMP_ROOT/$CASE-remote.git" --prompts-remote="$TMP_ROOT/$CASE-remote.git"
expect_refused "$W" "the docs and prompts repos need different remote URLs"
[ -z "$(git --git-dir="$TMP_ROOT/$CASE-remote.git" for-each-ref)" ] || fail "the remote was pushed to"

# --- free text written into the generated files -----------------------------------------------

# check_text_refused NAME TEXT FLAGS... - a bad value for --desc or --holder is refused.
check_text_refused() {
  CASE="$1"; local text="$2"; shift 2
  W="$TMP_ROOT/$CASE"; copy_template "$W"
  run_init "$W" "${BASE[@]}" --slug="$CASE" --layout=multi --remotes=no "$@"
  expect_refused "$W" "$text"
}

check_text_refused holder-spaces "a blank value is not an answer: Copyright holder" \
  --desc="Checks" --license=mit --holder='   '
check_text_refused desc-tab-space "a blank value is not an answer: One-line description" \
  --desc="$(printf '\t ')" --license=proprietary
check_text_refused desc-newline "invalid --desc (or INIT_DESC): it must be a single line" \
  --desc="$(printf 'First line\n# Heading')" --license=proprietary
check_text_refused desc-carriage-return "invalid --desc (or INIT_DESC): it must be a single line" \
  --desc="$(printf 'First line\r# Heading')" --license=proprietary
check_text_refused holder-newline "invalid --holder (or INIT_HOLDER): it must be a single line" \
  --desc="Checks" --license=mit --holder="$(printf 'Acme\nSecond line')"
check_text_refused desc-placeholder "invalid --desc (or INIT_DESC): it must not contain a {{NAME}} placeholder" \
  --desc='Uses {{TRUNK_BRANCH}} here' --license=proprietary
check_text_refused holder-placeholder "invalid --holder (or INIT_HOLDER): it must not contain a {{NAME}} placeholder" \
  --desc="Checks" --license=mit --holder='{{PROJECT}} Inc'

# Must proceed: braces that are not a placeholder are kept exactly as given.
CASE=desc-braces
W="$TMP_ROOT/$CASE"; copy_template "$W"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc='Renders {{templates}} fast' \
  --license=proprietary --layout=multi --remotes=no
expect_finished
grep -Fxq 'Renders {{templates}} fast' "$W/Code/$CASE-docs/AGENTS.md" \
  || fail "the description was not written as given"

# A typed answer is asked again rather than refused.
CASE=desc-typed-again
W="$TMP_ROOT/$CASE"; copy_template "$W"
set +e
( cd "$W" && printf 'Has {{PROJECT}} in it\nPlain description\n' | \
    ./init.sh --slug="$CASE" --license=proprietary --layout=multi --collab=solo --remotes=no ) \
  >"$TMP_ROOT/$CASE.out" 2>&1
STATUS=$?
set -e
OUT="$TMP_ROOT/$CASE.out"
expect_finished
grep -Fq -- "-> it must not contain a {{NAME}} placeholder" "$OUT" || fail "the answer was not refused"
grep -Fxq 'Plain description' "$W/Code/$CASE-docs/AGENTS.md" || fail "the second answer was not used"

# --- the folder's own empty origin is named before anything changes ---------------------------

# with_origin CASE - a template copy with an empty origin attached; sets W and ORIGIN.
with_origin() {
  CASE="$1"
  W="$TMP_ROOT/$CASE"; ORIGIN="$TMP_ROOT/$CASE-origin.git"
  copy_template "$W"; bare_remote "$ORIGIN"
  ( cd "$W" && git init -q && git remote add origin "$ORIGIN" )
}

with_origin reuse-manual
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=mit --holder="Test" \
  --layout=mono --remotes=yes --remote-provider=manual
expect_finished
expect_pre "note: this folder already has an empty origin"
expect_pre "$ORIGIN"
expect_pre "It is reused as the project's remote, and the project will be pushed to it."
expect_not_in "not creating a repository on GitHub" "$PRE"
# A clean folder with its own .git has nothing stray in it.
expect_not_in "which are not part of the template" "$OUT"

with_origin reuse-no-remotes
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=proprietary \
  --layout=mono --remotes=no
expect_finished
expect_pre "note: this folder already has an empty origin"
expect_pre "It is kept as the project's remote. Nothing will be pushed to it."
# Nothing is pushed, so there is nothing to caution about.
expect_not_in "this project is proprietary" "$OUT"

# The owner and visibility flags name a repository that is not created, so neither applies, and a
# declared public visibility does not stand in for the reused repository's own.
with_origin reuse-github-flags
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=proprietary \
  --layout=mono --remotes=yes --owner=throughstone-test --visibility=public
expect_finished
expect_pre "note: not creating a repository on GitHub"
expect_pre "note: ignoring --owner — no repository is created"
expect_pre "note: ignoring --visibility — no repository is created"
expect_not_in "WARNING: public visibility" "$OUT"
caution_names "$ORIGIN"
[ ! -s "$GH_LOG" ] || { fail "gh was called for a reused origin"; cat "$GH_LOG" >&2; }

# Keeping the origin needs no gh at all, and the flags are still only noted.
with_origin reuse-github-flags-no-gh
RUN_PATH="$(path_without_gh)" run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" \
  --license=proprietary --layout=mono --remotes=yes --owner=throughstone-test --visibility=public
expect_finished
grep -Fq "Note: 'gh' not found" "$OUT" || fail "the run could still see gh"
expect_pre "note: not creating a repository on GitHub"
expect_pre "note: ignoring --owner — no repository is created"
[ -n "$(git --git-dir="$ORIGIN" for-each-ref refs/heads)" ] || fail "nothing was pushed to the origin"

# If the kept origin cannot be attached after the boundary, nothing is created in its place: the
# GitHub path asked for no owner. A git template that already defines an origin makes the attach
# fail.
with_origin reuse-attach-fails
mkdir -p "$TMP_ROOT/$CASE-template"
printf '[remote "origin"]\n\turl = %s\n' "$TMP_ROOT/$CASE-elsewhere.git" > "$TMP_ROOT/$CASE-template/config"
GIT_TEMPLATE_DIR="$TMP_ROOT/$CASE-template" run_init "$W" "${BASE[@]}" --slug="$CASE" \
  --desc="Checks" --license=proprietary --layout=mono --remotes=yes
[ "$STATUS" -eq 1 ] || { fail "expected exit 1, got $STATUS"; cat "$OUT" >&2; }
grep -Fq "could not attach the existing origin" "$OUT" || fail "the attach did not fail as set up"
grep -Fq "The remote backup did not complete for: $CASE" "$OUT" || fail "the failure was not reported"
[ ! -s "$GH_LOG" ] || { fail "gh was called with no owner"; cat "$GH_LOG" >&2; }

# --- a proprietary push to a repository setup did not create -----------------------------------

# manual_multi CASE FLAGS... - multi layout with two empty manual remotes; FLAGS give the licence
# and anything else the case needs.
manual_multi() {
  CASE="$1"; shift
  W="$TMP_ROOT/$CASE"; copy_template "$W"
  bare_remote "$TMP_ROOT/$CASE-docs.git"; bare_remote "$TMP_ROOT/$CASE-prompts.git"
  run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --layout=multi \
    --remotes=yes --remote-provider=manual \
    --docs-remote="$TMP_ROOT/$CASE-docs.git" --prompts-remote="$TMP_ROOT/$CASE-prompts.git" "$@"
}

manual_multi caution-proprietary --license=proprietary
expect_finished
caution_names "$TMP_ROOT/$CASE-docs.git"
caution_names "$TMP_ROOT/$CASE-prompts.git"

CASE=caution-mono-url
W="$TMP_ROOT/$CASE"; copy_template "$W"
bare_remote "$TMP_ROOT/$CASE-remote.git"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=proprietary --layout=mono \
  --remotes=yes --remote-provider=manual --remote-url="$TMP_ROOT/$CASE-remote.git"
expect_finished
caution_names "$TMP_ROOT/$CASE-remote.git"

manual_multi caution-open-source --license=mit --holder="Test"
expect_finished
expect_not_in "this project is proprietary" "$OUT"

# A repository declared public gets the warning, and the caution would only repeat it.
manual_multi caution-declared-public --license=proprietary --visibility=public
expect_finished
expect_pre "WARNING: public visibility with a proprietary license"
expect_not_in "this project is proprietary" "$OUT"

# --- files a mono project's first commit would take in -----------------------------------------

CASE=stray-mono
W="$TMP_ROOT/$CASE"; copy_template "$W"
printf 'notes\n' > "$W/notes.txt"; printf 'KEY=\n' > "$W/.env.example"
for f in .DS_Store .gitattributes TODO.md .env .env.local x.swp; do printf 'x\n' > "$W/$f"; done
for d in .claude .dev .throughstone .test-fixtures .secrets; do mkdir -p "$W/$d"; printf 'x\n' > "$W/$d/f"; done
# Not --non-interactive: the remotes question still follows the layout, and the warning has to
# come before it, where stopping is still possible.
set +e
( cd "$W" && printf 'n\n' | ./init.sh --slug="$CASE" --desc="Checks" --license=proprietary \
    --layout=mono --collab=solo ) >"$TMP_ROOT/$CASE.out" 2>&1
STATUS=$?
set -e
OUT="$TMP_ROOT/$CASE.out"; PRE="$TMP_ROOT/$CASE.pre"
sed -n '1,/Detaching from the template/p' "$OUT" > "$PRE"
expect_finished
expect_pre "which are not part of the template"
expect_pre "    notes.txt"
expect_pre "    .env.example"
for f in .DS_Store .gitattributes TODO.md .env .env.local x.swp .claude .dev .throughstone \
  .test-fixtures .secrets; do
  if grep -Fxq "    $f" "$PRE"; then fail "named $f, which the warning skips"; fi
done
warn_line="$(grep -n -F "not part of the" "$OUT" | head -n 1 | cut -d: -f1)"
ask_line="$(grep -n -F "Online backup / sharing" "$OUT" | head -n 1 | cut -d: -f1)"
[ -n "$warn_line" ] && [ -n "$ask_line" ] && [ "$warn_line" -lt "$ask_line" ] \
  || fail "the warning did not come before the remotes question"
# A warning, not a refusal: the file is still committed.
git -C "$W" cat-file -e HEAD:notes.txt 2>/dev/null || fail "the run did not carry on"

# The multi root is not a repository, so nothing there is committed.
CASE=stray-multi
W="$TMP_ROOT/$CASE"; copy_template "$W"
printf 'notes\n' > "$W/notes.txt"
run_init "$W" "${BASE[@]}" --slug="$CASE" --desc="Checks" --license=proprietary \
  --layout=multi --remotes=no
expect_finished
expect_not_in "which are not part of the template" "$OUT"

if [ "$FAILED" != "0" ]; then
  exit 1
fi
echo "init.sh pre-boundary checks: PASS"
