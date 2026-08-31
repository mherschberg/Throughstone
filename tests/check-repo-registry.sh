#!/usr/bin/env bash
#
# Regression coverage for check 11 — scripts/check.sh's repo registry check.
#
# Two things are under test, and the second matters as much as the first: what the check
# reports, and that without --check-in it prints a skipped section and produces no finding. The
# registry changes when a repo is created, adopted or split out; the doctor runs on every push
# and all through a STEP, so a typo in repos.yml must not fail a build. A suite that only
# exercised --check-in would not notice the check leaking back onto the common path, which is
# the thing it was moved off.
#
# Findings are read out of check 11's own section, WITH their severity marker, so that a finding
# from an unrelated check cannot satisfy one of these and a FAIL quietly downgraded to a WARN
# cannot hide behind some other check's failure. Exit status is necessarily whole-run — that is
# what a FAIL means — so it is asserted beside the section, never instead of it. A missing
# remote is a WARN and leaves the exit code at 0, so $? alone would not see that finding at all.
#
# Pinned on purpose, so a red assertion is known to be real: the two hint sentences, which are
# the check's only actionable advice and one of which carries an ordering decision — push first,
# record the URL after — and the row count in the pass line. Names are listed in registry order
# and asserted as they fall out; a walk that reorders them shows up here.
#
# Deliberately absent, and not an oversight to fill in: anything asserting the registry's shape
# — the check reads two fields and does not police the file, so a malformed row is fixed by
# whoever just edited it — and the no-registry branch, which has no logic in it and reports a
# conspicuous state to someone already reading the output. This file grows only if the check does.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-registry-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0
note() { printf '  %s\n' "$1"; }
bad()  { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

# copy_template DEST — build a template fixture from HEAD, then overlay current worktree
# changes. Archiving rather than copying the live tree leaves ignored maintainer files behind,
# so the fixture is the shape a user downloads; the overlay keeps uncommitted edits under test.
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

# bootstrap NAME LAYOUT LICENSE — generate a project and echo its workspace root. The layout is
# what this file turns on; the license is varied only so that neither fixture is an all-default
# configuration, and has nothing to do with check 11.
bootstrap() {
  local name="$1" layout="$2" license="$3"
  local work="$TMP_ROOT/$name"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Repo registry check test" \
      --license="$license" \
      --holder="Throughstone Test" \
      --layout="$layout" \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.init.out" 2>&1 || {
    bad "$name: init.sh failed"
    sed -n '1,40p' "$TMP_ROOT/$name.init.out" >&2
    return 1
  }
  printf '%s\n' "$work"
}

registry_of() { set -- "$1"/Code/*-docs/registries/repos.yml; printf '%s\n' "$1"; }
doctor_of()   { set -- "$1"/Code/*-docs/scripts/check.sh;      printf '%s\n' "$1"; }

# doctor WORK [ARGS...] — run the generated project's doctor. DOC_STATUS is the exit status and
# DOC_OUT the whole run; SEC is check 11's section alone, which is what the assertions read.
doctor() {
  local work="$1"; shift
  DOC_OUT="$(bash "$(doctor_of "$work")" "$@" 2>&1)"
  DOC_STATUS=$?
  SEC="$(printf '%s\n' "$DOC_OUT" | awk '/^11\. Repo registry/ { f = 1 } f && /^Summary$/ { exit } f')"
  [ -n "$SEC" ] || bad "the doctor printed no check 11 section at all (args: ${*:-none})"
}

has()    { case "$SEC" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect() { has "$1" || bad "$2 — expected check 11 to report: $1"; }
refute() { has "$1" && bad "$2 — check 11 should NOT report: $1"; return 0; }
result() { case "$DOC_OUT" in *"RESULT: $1"*) ;; *) bad "$2 — expected RESULT: $1" ;; esac; }

# clean LABEL — the section reported nothing and the run passed. The guard against an assertion
# that cannot fail: every case that expects a finding is paired with a case that must not have
# one, so a check that had silently stopped reporting could not pass this file.
clean() {
  refute "[FAIL]" "$1"
  refute "[WARN]" "$1"
  result OK "$1"
  [ "$DOC_STATUS" -eq 0 ] || bad "$1 — expected exit 0, got $DOC_STATUS"
}

# landed LABEL REG — the fixture edit above actually changed the file. A row renamed upstream,
# or a typo in a call, would otherwise leave the registry as it was and a case would pass for
# the wrong reason: the state it meant to create is the state it was already in.
landed() { cmp -s "$TMP_ROOT/reg.before" "$2" && bad "fixture: $1 changed nothing"; return 0; }

# set_field WORK ROW FIELD VALUE — write a row-level field, replacing it if the row already
# carries one. Anchored on the row block — from a `- name:` to the next — which is the rewrite
# rule registries/repos.yml states for anything that edits it.
set_field() {
  local reg; reg="$(registry_of "$1")"
  cp "$reg" "$TMP_ROOT/reg.before"
  ROW="$2" FIELD="$3" VALUE="$4" perl -0pi -e '
    my $line = qq{    $ENV{FIELD}: "$ENV{VALUE}"\n};
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{ROW}\E"\n(?:(?!^[ \t]*-[ \t]*name:).)*?)^[ \t]*\Q$ENV{FIELD}\E:[^\n]*\n}
     {$1 . $line}ems
    or
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{ROW}\E"\n)}{$1 . $line}em;
  ' "$reg"
  landed "set $3 on row $2" "$reg"
}

# drop_field WORK ROW FIELD — delete one field from one row, leaving the rest of the row intact.
drop_field() {
  local reg; reg="$(registry_of "$1")"
  cp "$reg" "$TMP_ROOT/reg.before"
  ROW="$2" FIELD="$3" perl -0pi -e '
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{ROW}\E"\n(?:(?!^[ \t]*-[ \t]*name:).)*?)^[ \t]*\Q$ENV{FIELD}\E:[^\n]*\n}
     {$1}ems;
  ' "$reg"
  landed "drop $3 from row $2" "$reg"
}

# --- 1. Greenfield, both layouts ----------------------------------------------
# A project the method just created has no remotes when init.sh is told to make none, so its
# first check-in warns — and names exactly the repos whose contents nothing else backs up.
multi="$(bootstrap "registry-multi" multi apache-2.0)" || exit 1
mono="$(bootstrap "registry-mono" mono bsd-3)"         || exit 1

# Multi has no workspace-root row, so each repo stands alone and both are named.
doctor "$multi" --check-in
note "multi greenfield: $(printf '%s\n' "$SEC" | grep -E '^  \[' | head -1)"
expect "[WARN] repo(s) with no remote: registry-multi-docs prompts" "multi greenfield"
expect "Push it somewhere and record the URL in remote:" "multi greenfield hint"
refute "[FAIL]" "multi greenfield"
result OK "multi greenfield"
[ "$DOC_STATUS" -eq 0 ] || bad "multi greenfield — a WARN must not change the exit code, got $DOC_STATUS"

# Mono's other rows are folders inside the one repository the project has, so whatever backs the
# root up backs them up too and only the root row is named. That holds here too, where nothing
# backs it up yet: one remote on the root would cover every row, so the root is the only
# actionable thing to name — the warning is about backup risk now, not about a future split. The
# root itself is covered by nothing else, so it is flagged like any other repo.
doctor "$mono" --check-in
note "mono greenfield: $(printf '%s\n' "$SEC" | grep -E '^  \[' | head -1)"
expect "[WARN] repo(s) with no remote: registry-mono" "mono greenfield"
refute "registry-mono-docs" "mono root covers the folders below it"
refute "prompts" "mono root covers prompts/ as well"
[ "$DOC_STATUS" -eq 0 ] || bad "mono greenfield — expected exit 0, got $DOC_STATUS"

# The row those two refutes rest on has to exist, or they pass for the wrong reason.
grep -qE '^[[:space:]]*location:[[:space:]]*"\."' "$(registry_of "$mono")" \
  || bad "mono registry has no workspace-root row (location: \".\")"

# --- 2. What a recorded remote covers ------------------------------------------
# Three cases which between them are the whole rule: a remote on the "." row covers every row,
# a remote on any other row covers only itself, and a row with none is named.
set_field "$mono" "registry-mono" remote "git@example.com:TEAM/registry-mono.git"
doctor "$mono" --check-in
expect "3 row(s): all have a location, and a recorded remote covers every one" "mono root remote"
clean "mono root remote"

set_field "$multi" "prompts" remote "git@example.com:TEAM/registry-multi-prompts.git"
doctor "$multi" --check-in
expect "[WARN] repo(s) with no remote: registry-multi-docs" "a sibling's remote covers only itself"
refute "prompts" "the row that has a remote is not named"

# An empty remote: is not a remote. runbooks/check-in.md tells the operator to fill in a field
# that is "absent or empty"; the doctor has to agree with it about the second half.
set_field "$multi" "registry-multi-docs" remote ""
doctor "$multi" --check-in
expect "[WARN] repo(s) with no remote: registry-multi-docs" "an empty remote reads as absent"

# --- 3. A row with no location: is a hard failure -------------------------------
# location: is what setup-workspace.sh clones into and what the STEP process reads, so a row
# without one is unusable — unlike a missing remote, which is a risk someone may have accepted
# on purpose. The two findings are independent, and both speak in the same run.
drop_field "$multi" "prompts" location
doctor "$multi" --check-in
expect "[FAIL] row(s) with no location: prompts" "missing location fails"
expect "give every row a location:" "missing location hint"
expect "[WARN] repo(s) with no remote: registry-multi-docs" "the remote warning still speaks"
result FAIL "missing location"
[ "$DOC_STATUS" -eq 1 ] || bad "missing location — expected exit 1, got $DOC_STATUS"

# --- 4. None of it runs without --check-in --------------------------------------
# The registry is still broken. A plain run is what CI does on every push and what the doctor
# does all through a STEP: it must report the check as skipped, not fail the build on a
# rare-path edit nobody on that path made.
doctor "$multi"
expect "skipped — run with --check-in" "default run skips the check"
refute "no location" "default run reports no finding from the registry"
clean "default run"

# --- 5. A commented row is not a row --------------------------------------------
# repos.yml ships a fully formed example row inside a comment block, and someone editing the
# file comments rows in and out. Neither is a repo the project has. The block appended here is
# missing everything the check looks for, so a reader that stopped anchoring its patterns to
# the start of the line would report it — and the count would move off the two real rows.
set_field "$multi" "prompts" location "prompts/"
set_field "$multi" "registry-multi-docs" remote "git@example.com:TEAM/registry-multi-docs.git"
cat >> "$(registry_of "$multi")" <<'YAML'

  # Parked while we decide whether to split this out:
  # - name: "registry-multi-parked"
  #   type: service
YAML
doctor "$multi" --check-in
expect "2 row(s): all have a location, and a recorded remote covers every one" "commented rows are not counted"
refute "registry-multi-parked" "a row commented out by hand is not read"
refute "registry-multi-api" "the example row repos.yml ships is not read"
clean "commented rows are not counted"

if [ "$failures" -ne 0 ]; then
  printf 'check.sh repo registry check: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
echo "check.sh repo registry check: PASS"
