#!/usr/bin/env bash
#
# Regression coverage for check 10 — scripts/check.sh's repo registry check.
#
# Two things are under test, and the second matters as much as the first: what the check
# reports, and that without --check-in it prints a skipped section and produces no finding. The
# registry changes when a repo is created, adopted or split out; the doctor runs on every push
# and all through a STEP, so a typo in repos.yml must not fail a build. A suite that only
# exercised --check-in would not notice the check leaking back onto the common path, which is
# the thing it was moved off.
#
# Findings are read out of check 10's own section, WITH their severity marker, so that a finding
# from an unrelated check cannot satisfy one of these and a FAIL quietly downgraded to a WARN
# cannot hide behind some other check's failure. Exit status is necessarily whole-run — that is
# what a FAIL means — so it is asserted beside the section, never instead of it. A missing
# remote is a WARN and leaves the exit code at 0, so $? alone would not see that finding at all.
#
# Pinned on purpose, so a red assertion is known to be real: the hint sentences, which are the
# check's only actionable advice, and the row counts in the pass line and in the failure for a
# row the check did not read. Names are listed in registry order and asserted as they fall out; a
# walk that reorders them shows up here.
#
# Deliberately absent, and not an oversight to fill in: anything asserting the registry's shape
# beyond whether every row was read — the check reads two fields and does not police the file, so
# a malformed row is fixed by whoever just edited it — and the no-registry branch, which has no
# logic in it and names a file a reader can see is not there. A registry that is there and holds
# no rows is the opposite case, and it is covered below: nothing in the output says so unless the
# check says it. This file grows only if the check does.

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
# configuration, and has nothing to do with check 10.
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
# DOC_OUT the whole run; SEC is check 10's section alone, which is what the assertions read.
doctor() {
  local work="$1"; shift
  DOC_OUT="$(bash "$(doctor_of "$work")" "$@" 2>&1)"
  DOC_STATUS=$?
  # The heading names the registry file, and that name now carries the project slug, so the
  # assertions read the section body only: a refutation must not match the path in a heading.
  SEC="$(printf '%s\n' "$DOC_OUT" | awk '/^10\. Repo registry/ { f = 1; next } f && /^Summary$/ { exit } f')"
  case "$DOC_OUT" in
    *"10. Repo registry"*) ;;
    *) bad "the doctor printed no check 10 section at all (args: ${*:-none})" ;;
  esac
}

has()    { case "$SEC" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect() { has "$1" || bad "$2 — expected check 10 to report: $1"; }
refute() { has "$1" && bad "$2 — check 10 should NOT report: $1"; return 0; }
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
# first check-in warns — and names exactly the repos whose contents nothing else backs up. Each
# is named with its location, because the fix is to go and push that repo and a name on its own
# does not say where it is; the assertions below carry both, so dropping the location fails them.
multi="$(bootstrap "registry-multi" multi apache-2.0)" || exit 1
mono="$(bootstrap "registry-mono" mono bsd-3)"         || exit 1

# Both layouts declare themselves, and the line is above the rows. Placement is not cosmetic:
# anything that rewrites a row scans forward from its `- name:` to the next one and nothing bounds
# that scan at the end of the list, so a top-level key written below the rows sits inside the last
# row's block, where a rewriter reaches it and writes it back as one of that row's fields. Read as
# line numbers rather than by eye, because a file that declares the right value in the wrong place
# passes every other assertion in this file.
declares() {
  local reg lay rep; reg="$(registry_of "$1")"
  lay="$(grep -n "^layout: $2\$" "$reg" | head -1 | cut -d: -f1)"
  rep="$(grep -n '^repos:$' "$reg" | head -1 | cut -d: -f1)"
  [ -n "$lay" ] || { bad "init.sh wrote no \`layout: $2\` line at the left margin of the $2 registry"; return 0; }
  [ -n "$rep" ] || { bad "the $2 registry has no repos: key to place the declaration against"; return 0; }
  [ "$lay" -lt "$rep" ] || bad "the $2 registry declares its layout on line $lay, below repos: on line $rep — inside the last row's block"
}
declares "$multi" multi
declares "$mono" mono

# Multi has no workspace-root row, so each repo stands alone and both are named.
doctor "$multi" --check-in
note "multi greenfield: $(printf '%s\n' "$SEC" | grep -E '^  \[' | head -1)"
expect "[WARN] repo(s) with no remote: registry-multi-docs (Code/registry-multi-docs/) prompts (prompts/)" "multi greenfield"
expect "private, widening is a separate decision" "multi greenfield hint"
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
expect "[WARN] repo(s) with no remote: registry-mono (.)" "mono greenfield"
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
expect "3 row(s) in a mono project: all have a location, and a recorded remote covers every one" "mono root remote"
clean "mono root remote"

set_field "$multi" "prompts" remote "git@example.com:TEAM/registry-multi-prompts.git"
doctor "$multi" --check-in
expect "[WARN] repo(s) with no remote: registry-multi-docs (Code/registry-multi-docs/)" "a sibling's remote covers only itself"
refute "prompts" "the row that has a remote is not named"

# An empty remote: is not a remote. runbooks/check-in.md tells the operator to fill in a field
# that is "absent or empty"; the doctor has to agree with it about the second half.
set_field "$multi" "registry-multi-docs" remote ""
doctor "$multi" --check-in
expect "[WARN] repo(s) with no remote: registry-multi-docs (Code/registry-multi-docs/)" "an empty remote reads as absent"

# --- 3. A row with no location: is a hard failure -------------------------------
# location: is the workspace-relative path the repo lives at, so a row without one is unusable —
# unlike a missing remote, which is a risk someone may have accepted on purpose. The two findings
# are independent, and both speak in the same run.
drop_field "$multi" "prompts" location
doctor "$multi" --check-in
expect "[FAIL] row(s) with no location: prompts" "missing location fails"
expect "give every row a location:" "missing location hint"
expect "[WARN] repo(s) with no remote: registry-multi-docs (Code/registry-multi-docs/)" "the remote warning still speaks"
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
# file comments rows in and out. Neither is a repo the project has. Every pattern the check
# matches is anchored to the start of the line, so the comment skip in front of them is a second
# guard: the block appended here is reported only by a reader that has lost both, and the count
# would move off the two real rows. A value that mentions `- name:` is not a row either, and it
# is what a row pattern that has lost its anchor alone trips on.
set_field "$multi" "prompts" location "prompts/"
set_field "$multi" "registry-multi-docs" remote "git@example.com:TEAM/registry-multi-docs.git"
set_field "$multi" "prompts" description "A value that mentions - name: is not a row"
cat >> "$(registry_of "$multi")" <<'YAML'

  # Parked while we decide whether to split this out:
  # - name: "registry-multi-parked"
  #   type: service
YAML
doctor "$multi" --check-in
expect "2 row(s) in a multi project: all have a location, and a recorded remote covers every one" "commented rows are not counted"
refute "registry-multi-parked" "a row commented out by hand is not read"
refute "registry-multi-api" "the example row repos.yml ships is not read"
clean "commented rows are not counted"

# --- 6. A row the check did not read fails --------------------------------------
# A row is found by its `- name:` line, so a row written any other way is not read, and its
# fields land on the row above it. Every list entry is counted apart from that walk, and a
# registry whose two counts disagree fails. Each registry below holds two repos and is read as
# fewer; the third, where only one row is out of order, is the shape the zero-row check in
# section 7, or a test for a bare `-`, passes — which is what the count is here for.
unread() {
  local label="$1" pin="$2"
  cat > "$(registry_of "$multi")"
  doctor "$multi" --check-in
  expect "[FAIL] $pin" "$label"
  expect "start every row with its - name: line" "$label hint"
  refute "all have a location" "$label"
  # The first registry below is read as no rows at all, which is the state the zero-row warning in
  # section 7 also reads — and the only thing separating them is that this one still holds list
  # entries. The count failure is the finding that names what to do here, so the warning must not
  # speak over it with advice to restore rows that are sitting right there in the wrong shape.
  refute "found no repo rows" "$label — rows the walk could not read are not an empty registry"
  result FAIL "$label"
  [ "$DOC_STATUS" -eq 1 ] || bad "$label — expected exit 1, got $DOC_STATUS"
}

unread "every row starts with its location" "read 0 of 2 row(s)" <<'YAML'
layout: multi

repos:
  - location: "Code/alpha/"
    name: "alpha"
  - location: "Code/beta/"
    name: "beta"
YAML

unread "the second row starts on a bare dash" "read 1 of 2 row(s)" <<'YAML'
layout: multi

repos:
  - name: "alpha"
    location: "Code/alpha/"
  -
    name: "beta"
    location: "Code/beta/"
YAML

unread "only the second row is out of order" "read 1 of 2 row(s)" <<'YAML'
layout: multi

repos:
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"
  - location: "Code/beta/"
    name: "beta"
YAML

# --- 7. A registry with no rows in it ---------------------------------------------
# Emptying the file is quieter than deleting it: a deleted registry warns before the walk, and a
# row the walk cannot read fails, but a registry with nothing in it read as a clean pass over zero
# rows — a pass vouching for the whole inventory on the strength of having read none of it. Zero
# rows is not a project with no repos: this file lives in the docs hub, which has a row of its
# own, and init.sh writes that row and prompts/ before anyone can run the doctor.
#
# Three shapes, because each rules out a different way of writing the check. The file emptied
# outright is the plain case. The `repos:` key left behind with nothing under it is what a test
# for an empty file passes. Every row commented out is what a test that greps the file for a
# `- name:` line passes, since a commented row still carries one.
empty_registry() {
  doctor "$multi" --check-in
  expect "[WARN] found no repo rows in Code/registry-multi-docs/registries/repos.yml — nothing to check" "$1"
  expect "a registry with neither has lost them" "$1 hint"
  refute "[PASS]" "$1"
  refute "[FAIL]" "$1"
  result OK "$1"
  [ "$DOC_STATUS" -eq 0 ] || bad "$1 — a WARN must not change the exit code, got $DOC_STATUS"
}

: > "$(registry_of "$multi")"
empty_registry "emptied registry"

printf 'repos:\n' > "$(registry_of "$multi")"
empty_registry "registry with its key and no rows under it"

cat > "$(registry_of "$multi")" <<'YAML'
repos:
  # - name: "registry-multi-parked"
  #   location: "Code/registry-multi-parked/"
YAML
empty_registry "registry whose every row is commented out"

# The control, and the guard against a warning that fires on any registry at all: one row is a
# row, and the pass line comes back with its count.
cat > "$(registry_of "$multi")" <<'YAML'
layout: multi

repos:
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"
YAML
doctor "$multi" --check-in
expect "1 row(s) in a multi project: all have a location, and a recorded remote covers every one" "one row is not none"
refute "found no repo rows" "one row is not none"
clean "one row is not none"

# --- 8. A registry nothing can read ------------------------------------------------
# `-f` is type and existence, not readability, so a registry that is entirely intact and merely
# unreadable walks to zero rows exactly as an empty one does. It gets its own finding, because the
# empty registry's advice — restore the rows — is wrong for a file whose rows never left.
chmod 000 "$(registry_of "$multi")"
# chmod 000 does not stop a privileged reader, and the case would then pass having exercised
# nothing at all. Establish the precondition rather than assume it, as the setup-workspace suite
# does for the same fixture.
head -c1 "$(registry_of "$multi")" >/dev/null 2>&1 \
  && bad "unreadable registry: the fixture is still readable, so this case proved nothing"
doctor "$multi" --check-in
chmod 644 "$(registry_of "$multi")"
expect "[WARN] cannot read Code/registry-multi-docs/registries/repos.yml — skipping repo registry check" "unreadable registry"
refute "found no repo rows" "an unreadable registry is not an empty one"
refute "[PASS]" "unreadable registry"
refute "[FAIL]" "unreadable registry"
result OK "unreadable registry"

# --- 9. The layout the registry declares, and the rows agreeing with it -----------
# The coverage rule above asks whether a row's work is backed up anywhere, and the answer depends
# on which layout the project is in: under `multi` every row answers for itself, under `mono` the
# workspace-root row's remote covers the folders inside it. That is read from the `layout:` line
# the registry declares and from nothing else — the rows cannot say it, because a mono project has
# MORE rows than a multi one and the `.` row can never be required of a multi project, so its
# absence means multi, or a project made before the field existed, and no check can tell those
# apart.
#
# So the declaration is one fact and the rows are another, and a fact kept in two places drifts.
# Each case below is a way they can disagree, and the pass at the end is the control: a check that
# had stopped reconciling would satisfy every refutation here and fail that one.
#
# Whole registries rather than edits, because what is under test includes a line that is not in a
# row and a row that is not there at all.
reg_is() {
  cat > "$(registry_of "$multi")"
  doctor "$multi" --check-in
}

# An undeclared registry is the shape every project bootstrapped before the field has. Nothing
# guesses a layout from it, so the coverage rule does not run: the finding is the missing line,
# and the WARN naming repos it cannot judge must not come back beside it. That WARN, on exactly
# this shape, is what this whole field replaces.
reg_is <<'YAML'
repos:
  - name: "alpha"
    location: "Code/alpha/"
  - name: "beta"
    location: "beta/"
YAML
expect "[WARN] Code/registry-multi-docs/registries/repos.yml does not declare a layout" "an undeclared registry"
expect "layout: mono if the workspace root is the one repository" "an undeclared registry hint"
refute "no remote" "an undeclared layout is not judged for coverage"
refute "[PASS]" "an undeclared layout does not pass"
refute "[FAIL]" "an undeclared layout is a question, not drift"
result OK "an undeclared registry"

# One declaration, and it has to be findable. Two lines and the layout is whatever the bottom one
# says, which is how someone who follows the warning above — add the line at the top — ends up
# overruled by the stale line they meant to replace. A line below the rows is inside the last row
# block for anything that rewrites a row, which is what its placement rule exists for; nothing
# else in the file could ever catch that, because a reader looking for `^layout:` finds it either
# way.
reg_is <<'YAML'
layout: multi

layout: mono

repos:
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"
YAML
expect "[FAIL] Code/registry-multi-docs/registries/repos.yml declares a layout 2 times" "two declarations"
expect "keep one layout: line" "two declarations hint"
refute "[PASS]" "two declarations"
result FAIL "two declarations"

reg_is <<'YAML'
repos:
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"

layout: multi
YAML
expect "[FAIL] Code/registry-multi-docs/registries/repos.yml declares its layout below the rows" "a declaration below the rows"
expect "move the layout: line above repos:" "a declaration below the rows hint"
refute "[PASS]" "a declaration below the rows"
result FAIL "a declaration below the rows"

# A line with nothing after it is not the absent case, and must not be answered with the warning
# that tells the reader to add a line: they would add one and the empty line below would win.
reg_is <<'YAML'
layout:

repos:
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"
YAML
expect "[FAIL] Code/registry-multi-docs/registries/repos.yml has a layout: line with nothing after it" "an empty declaration"
refute "does not declare a layout" "an empty declaration is not the absent one"
result FAIL "an empty declaration"

# `.` and `./` are one path. Comparing the spelling puts a root row written the second way outside
# every rule here: a mono project is told its root row is missing AND that the row is a separate
# repository, and a multi project carrying one is not told at all.
reg_is <<'YAML'
layout: mono

repos:
  - name: "root"
    location: "./"
    remote: "git@example.com:TEAM/root.git"
  - name: "alpha-docs"
    location: "Code/alpha-docs/"
YAML
expect "2 row(s) in a mono project: all have a location, and a recorded remote covers every one" "a root row spelled ./"
clean "a root row spelled ./"

reg_is <<'YAML'
layout: multi

repos:
  - name: "root"
    location: "./"
    remote: "git@example.com:TEAM/root.git"
YAML
expect 'declares layout: multi and carries a row whose location: is "."' "a multi root row spelled ./"

# The rows are compared against the declaration only when the walk read all of them. A row written
# fields-first is not read, and its remote: lands on the row above (the count failure says so), so
# judging the rows here would report a root row that is present as missing and a folder that
# inherited a remote as a repository of its own — and send the reader to a repository conversion
# over a field in the wrong order. That is the one row the 1.8 migration asks a mono project to
# type by hand.
reg_is <<'YAML'
layout: mono

repos:
  - name: "alpha-docs"
    location: "Code/alpha-docs/"
  - location: "."
    name: "root"
    remote: "git@example.com:TEAM/root.git"
YAML
expect "[FAIL] read 1 of 2 row(s)" "a row the walk could not read"
refute "has no row for the workspace root" "a row the walk could not read is not a missing root row"
refute "registers a separate repository" "a leaked remote: is not a second repository"

# Under multi a `.` row is condemned above, and naming it again as a repo with no remote would tell
# the reader to give a remote to the row they were just told to delete.
reg_is <<'YAML'
layout: multi

repos:
  - name: "root"
    location: "."
  - name: "alpha"
    location: "Code/alpha/"
    remote: "git@example.com:TEAM/alpha.git"
YAML
expect 'declares layout: multi and carries a row whose location: is "."' "a multi root row is condemned once"
refute "no remote: root" "the row told to be deleted is not also told to get a remote"

# A row with no location: is that row failing, not a second repository. The own-remote test asks
# whether a row is the workspace root, and an empty location is not `.`.
reg_is <<'YAML'
layout: mono

repos:
  - name: "root"
    location: "."
    remote: "git@example.com:TEAM/root.git"
  - name: "orphan"
    remote: "git@example.com:TEAM/orphan.git"
YAML
expect "[FAIL] row(s) with no location: orphan" "a row with no location"
refute "registers a separate repository" "a row with no location is not reported as a second repository"

# A value that is neither is not a third layout either, and it fails rather than warning: the file
# says something, and nothing can read it.
reg_is <<'YAML'
layout: monorepo

repos:
  - name: "alpha"
    location: "Code/alpha/"
YAML
expect "[FAIL] Code/registry-multi-docs/registries/repos.yml declares layout: monorepo, which is not a layout" "an unreadable layout value"
expect "the two values are mono and multi" "an unreadable layout value hint"
refute "no remote" "an unreadable layout value is not judged for coverage"
refute "[PASS]" "an unreadable layout value does not pass"
result FAIL "an unreadable layout value"
[ "$DOC_STATUS" -eq 1 ] || bad "an unreadable layout value — expected exit 1, got $DOC_STATUS"

# Declared mono with no workspace-root row: the state a 1.7 mono project upgrades from, and the
# one nothing could diagnose before, because the row's absence was the only signal there was. The
# folder rows must NOT be named here — telling a mono project to go and create remotes for the
# folders inside its one repository is the false warning this replaces.
reg_is <<'YAML'
layout: mono

repos:
  - name: "alpha-docs"
    location: "Code/alpha-docs/"
  - name: "prompts"
    location: "prompts/"
YAML
expect "[FAIL] declares layout: mono and has no row for the workspace root" "mono with no root row"
expect 'add a row whose location: is "."' "mono with no root row hint"
refute "no remote" "the folder rows of a mono project are not named as unbacked-up repos"
refute "[PASS]" "mono with no root row"
result FAIL "mono with no root row"

# Declared multi carrying one: the same disagreement from the other side. In multi the workspace
# root is a per-machine shell, so a row for it describes nothing.
reg_is <<'YAML'
layout: multi

repos:
  - name: "alpha"
    location: "."
    remote: "git@example.com:TEAM/alpha.git"
  - name: "beta"
    location: "Code/beta/"
    remote: "git@example.com:TEAM/beta.git"
YAML
expect 'declares layout: multi and carries a row whose location: is "."' "multi with a root row"
expect "delete the workspace-root row, or correct the declaration" "multi with a root row hint"
result FAIL "multi with a root row"

# Declared mono holding a separate repository — the state the method forbids. A mono project is
# one repository, so a row that is not the root and carries a remote of its own is a second one,
# and the way out is the conversion, not a registry edit.
reg_is <<'YAML'
layout: mono

repos:
  - name: "alpha"
    location: "."
    remote: "git@example.com:TEAM/alpha.git"
  - name: "sibling"
    location: "Code/sibling/"
    remote: "git@example.com:TEAM/sibling.git"
YAML
expect "[FAIL] declares layout: mono and registers a separate repository: sibling (Code/sibling/)" "mono holding a repo"
expect "runbooks/splitting-repos.md Case 2" "mono holding a repo is sent to the conversion"
result FAIL "mono holding a repo"

# Two disagreements at once, both reported. Nothing in this check exits early, and a registry
# missing its root row is not thereby excused the separate repository sitting beside it — they are
# independent defects with independent fixes, and a reader who is shown one and not the other goes
# back round the loop.
reg_is <<'YAML'
layout: mono

repos:
  - name: "alpha-docs"
    location: "Code/alpha-docs/"
  - name: "sibling"
    location: "Code/sibling/"
    remote: "git@example.com:TEAM/sibling.git"
YAML
expect "declares layout: mono and has no row for the workspace root" "two disagreements: the missing root row"
expect "declares layout: mono and registers a separate repository: sibling (Code/sibling/)" "two disagreements: the separate repository"
result FAIL "two disagreements at once"

# The control. Same rows as the case above with the second one made a folder again: every
# reconciliation above has to be able to come back clean, or they are assertions that cannot fail.
reg_is <<'YAML'
layout: mono

repos:
  - name: "alpha"
    location: "."
    remote: "git@example.com:TEAM/alpha.git"
  - name: "sibling"
    location: "Code/sibling/"
YAML
expect "2 row(s) in a mono project: all have a location, and a recorded remote covers every one" "a mono registry that agrees with itself"
clean "a mono registry that agrees with itself"

if [ "$failures" -ne 0 ]; then
  printf 'check.sh repo registry check: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
echo "check.sh repo registry check: PASS"
