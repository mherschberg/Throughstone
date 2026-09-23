#!/usr/bin/env bash
#
# Regression coverage for check 7 — scripts/check.sh's workspace-root hygiene check.
#
# The check answers one question per entry at the workspace root: did the method put this here,
# or does it belong inside a repo? Two ways of answering it wrongly are what this file pins.
#
# The first is a false warning. A repo may be registered at any path inside the workspace and is
# never made to move, so a row whose `location:` names a root-level folder is the project saying
# that folder belongs there. A check that decides from a fixed list alone cannot know that, warns
# about the repo on every run, and teaches whoever reads the section to stop reading it.
#
# The second is a false silence, and it is the quieter of the two. One allowed entry holds a
# space — `Upcoming Prompts` — so a membership test that cannot tell one entry with a space from
# two entries without one lets a stray through under either word. Every case below that expects a
# warning is paired with one that must not have it: a check that had stopped reporting anything
# would otherwise pass this file from end to end.
#
# The fixture is a multi-repo project, because check 7 stands down when the workspace root is
# itself a repository and when CI is set. Both branches are asserted at the end rather than
# assumed, and the doctor is run with CI unset throughout: whether the section under test runs at
# all must not depend on the environment the suite happens to be started in.
#
# `Upcoming` is the word the strays here are built from, and `Prompts` is not. They come from the
# same entry and fail the same way, but a case-insensitive filesystem resolves `Prompts` to the
# `prompts/` repo already at the root, so on macOS the entry a fixture means to create never
# exists and the case would pass without testing anything.
#
# Deliberately absent, and not an oversight to fill in: anything about whether a registered
# location exists on disk, holds a repo, or is spelled the way repos.yml requires. Check 7 asks
# only whether a root entry is accounted for; the rows themselves are check 10's subject and
# tests/check-repo-registry.sh's.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-hygiene-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

SLUG="hygiene"
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

# bootstrap — generate the project every case copies, and echo its workspace root. The layout is
# multi because that is the one whose root is not a repository, which is the only layout in which
# check 7 does any work.
bootstrap() {
  local work="$TMP_ROOT/$SLUG"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$SLUG" \
      --desc="Workspace-root hygiene check test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$SLUG.init.out" 2>&1 || {
    bad "init.sh failed"
    sed -n '1,40p' "$TMP_ROOT/$SLUG.init.out" >&2
    return 1
  }
  printf '%s\n' "$work"
}

# fixture LABEL — a fresh copy of the generated project for one case to change. The doctor finds
# its root from its own path, so the copy is a project in its own right.
fixture() {
  cp -R "$TMP_ROOT/$SLUG" "$TMP_ROOT/case-$1"
  printf '%s\n' "$TMP_ROOT/case-$1"
}

registry_of() { printf '%s\n' "$1/Code/$SLUG-docs/registries/repos.yml"; }

# add_row WORK NAME LOCATION — append a registry row, in the shape registries/repos.yml ships.
add_row() {
  cat >> "$(registry_of "$1")" <<YAML

  - name: "$2"
    location: "$3"
    type: service
    added_as: created
    description: "Registered by tests/check-root-hygiene.sh."
YAML
}

# doctor WORK — run the project's doctor with CI unset, and keep check 7's section alone. A
# finding from another check must not be able to satisfy an assertion about this one.
doctor() {
  DOC_OUT="$(env -u CI bash "$1/Code/$SLUG-docs/scripts/check.sh" 2>&1)"
  DOC_STATUS=$?
  SEC="$(printf '%s\n' "$DOC_OUT" | awk '/^7\. Workspace-root hygiene/ { f = 1; next } f && /^[0-9]+\. / { exit } f')"
  [ -n "$SEC" ] || bad "the doctor printed no check 7 section, or an empty one"
}

has()    { case "$SEC" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect() { has "$1" || bad "$2 — expected check 7 to report: $1"; }
refute() { has "$1" && bad "$2 — check 7 should NOT report: $1"; return 0; }

# quiet LABEL — the section said only that the root is as expected, and the run passed. Every
# case expecting a warning is paired with one of these.
quiet() {
  expect "[PASS] only the expected pointers / repos at the workspace root" "$1"
  refute "[WARN]" "$1"
  refute "[FAIL]" "$1"
  [ "$DOC_STATUS" -eq 0 ] || bad "$1 — expected exit 0, got $DOC_STATUS"
}

# stray LABEL NAME — the section named exactly this entry. The trailing dash is the start of the
# rest of the sentence, so a name that is a prefix of a longer one cannot satisfy it.
stray() {
  expect "unexpected entr(ies) at workspace root: $2 —" "$1"
  refute "[PASS]" "$1"
  [ "$DOC_STATUS" -eq 0 ] || bad "$1 — a WARN must not change the exit code, got $DOC_STATUS"
}

base="$(bootstrap)" || exit 1
# bootstrap runs in a command substitution, so anything it counted would be discarded with the
# subshell. The one thing every case below rests on is asserted out here instead: check 7 stands
# down when the workspace root is a repository, and would then run none of them.
[ -e "$base/.git" ] && bad "fixture: the multi-layout workspace root is a repository, so check 7 stands down in every case below"

# --- 1. A project the method just generated ---------------------------------------
# Nothing was added, so nothing is unexpected — and the entries that are there are the ones the
# cases below build on, so they are listed rather than trusted.
doctor "$base"
note "fresh project: $(printf '%s\n' "$SEC" | grep -E '^  \[' | head -1)"
quiet "fresh project"
for entry in "Code" "prompts" "Upcoming Prompts" "CLAUDE.md" "AGENTS.md"; do
  [ -e "$base/$entry" ] || bad "fixture: the generated workspace root has no $entry, so the cases below rest on nothing"
done

# --- 2. An entry nobody accounted for ----------------------------------------------
# The plain case, and the control for every refutation below: when something really is unexpected
# the check says so, names it, and says what to do about it.
c="$(fixture plain)"
mkdir "$c/scratch"
doctor "$c"
stray "an unaccounted entry" "scratch"
expect "no row in" "an unaccounted entry hint"
expect "registers a path starting at one" "an unaccounted entry hint"
expect "never has to move" "an unaccounted entry hint"

# --- 3. One word of an entry that holds a space ------------------------------------
# `Upcoming Prompts` is one allowed entry, not two. A test that joins the allowed entries on
# spaces and looks for " $name " inside the join lets `Upcoming` — and `Prompts`, which this
# fixture cannot create — through as allowed entries of their own.
c="$(fixture one-word)"
mkdir "$c/Upcoming"
doctor "$c"
stray "one word of a two-word entry" "Upcoming"
refute "Upcoming Prompts" "the intake folder itself is not named"
[ -e "$c/Upcoming Prompts" ] || bad "fixture: no 'Upcoming Prompts' at the root, so the case above proves nothing about it"

# --- 4. A repo registered at a root-level location ----------------------------------
# METHOD.md §7: a repo may sit at any path inside the workspace and is never made to move. A row
# that says so is the project accounting for that folder, and the check has to read it.
c="$(fixture registered)"
mkdir "$c/sidecar"
add_row "$c" "sidecar" "sidecar/"
doctor "$c"
note "registered at the root: $(printf '%s\n' "$SEC" | grep -E '^  \[' | head -1)"
quiet "a repo registered at a root-level location"

# --- 4b. The same location, spelled with a leading ./ ---------------------------------
# `./sidecar/` and `sidecar/` are one path. repos.yml requires only that a location stay inside
# the workspace, `scripts/setup-workspace.sh` clones the first spelling as readily as the second,
# and check 10 reads it as an ordinary row — so nothing else tells the writer it is a mistake,
# and a reader that took the head before the `./` came off would drop the row as the workspace
# root and warn about the repo anyway.
c="$(fixture dot-slash)"
mkdir "$c/sidecar"
add_row "$c" "sidecar" "./sidecar/"
doctor "$c"
quiet "a root-level location spelled ./sidecar/"

# --- 5. It is the location that accounts for the entry, not the name -----------------
# The same row, pointing where the method's own rows point. `Code/` is allowed already; `sidecar`
# at the root is not, and a check reading names rather than paths would clear it anyway.
c="$(fixture registered-elsewhere)"
mkdir "$c/sidecar"
add_row "$c" "sidecar" "Code/sidecar/"
doctor "$c"
stray "a row that registers the repo somewhere else" "sidecar"

# --- 6. A commented row registers nothing ---------------------------------------------
# repos.yml ships an example row inside a comment block, and someone deciding whether to split a
# repo out comments rows in and out. Neither is a location the project has taken.
c="$(fixture commented)"
mkdir "$c/sidecar"
cat >> "$(registry_of "$c")" <<'YAML'

  # Parked while we decide whether this is its own repo:
  # - name: "sidecar"
  #   location: "sidecar/"
YAML
doctor "$c"
stray "a commented-out row" "sidecar"

# --- 7. The workspace-root row accounts for the root, not for everything in it ---------
# A mono-repo-for-now project has a row whose location is `.`. That names the root itself, which
# is not an entry in it, so it must not read as clearing every entry there is.
c="$(fixture root-row)"
mkdir "$c/scratch"
add_row "$c" "$SLUG" "."
doctor "$c"
stray "a location of ." "scratch"

# --- 8. No registry to read -------------------------------------------------------------
# The fixed list is what the check has left, and it still works off it. Check 10 is what reports
# a registry that is not there; check 7 does not diagnose it a second time.
c="$(fixture no-registry)"
mkdir "$c/sidecar"
rm -f "$(registry_of "$c")"
doctor "$c"
stray "no registry at all" "sidecar"
refute "repos.yml — skipping" "check 7 does not diagnose a missing registry"
refute "awk" "check 7 does not run its reader over a registry that is not there"

# --- 8b. A registry that is there and cannot be read ------------------------------------
# The fixed list is all the check has, exactly as in case 8 — but here a row it could not read may
# well account for the entry it is about to name, and the advice has to say so rather than telling
# the reader to register a repo that is already registered.
c="$(fixture unreadable-registry)"
mkdir "$c/sidecar"
add_row "$c" "sidecar" "sidecar/"
chmod 000 "$(registry_of "$c")"
doctor "$c"
chmod 644 "$(registry_of "$c")"
stray "an unreadable registry" "sidecar"
expect "could not be read, so a repo registered at one is named here too" "an unreadable registry says so"
refute "no row in" "an unreadable registry does not claim the rows were read"
refute "awk" "check 7 does not run its reader over a registry it cannot read"

# --- 9. Where the check stands down --------------------------------------------------------
# Root hygiene is a statement about a local multi-repo workspace. In CI one repo is checked out
# and the rest of the root is absent; when the root is itself a repository its contents are that
# repository's business. Both are asserted with a real stray in place, so a branch that had
# stopped standing down fails here.
c="$(fixture ci)"
mkdir "$c/scratch"
DOC_OUT="$(CI=true bash "$c/Code/$SLUG-docs/scripts/check.sh" 2>&1)"
DOC_STATUS=$?
SEC="$(printf '%s\n' "$DOC_OUT" | awk '/^7\. Workspace-root hygiene/ { f = 1; next } f && /^[0-9]+\. / { exit } f')"
expect "[PASS] CI environment" "CI stands the check down"
refute "scratch" "CI stands the check down"

c="$(fixture root-is-a-repo)"
mkdir "$c/scratch"
git -C "$c" init -q
doctor "$c"
expect "[PASS] workspace root is itself a repo" "a repo at the root stands the check down"
refute "scratch" "a repo at the root stands the check down"

if [ "$failures" -ne 0 ]; then
  printf 'workspace-root hygiene: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
printf 'workspace-root hygiene: PASS\n'
