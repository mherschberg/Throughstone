#!/usr/bin/env bash
#
# Regression coverage for scripts/setup-workspace.sh — the script every developer after the
# first runs to assemble the project on their machine.
#
# One property is under test: the workspace always gets assembled. The script clones the repos
# the registry lists, and every measured way a clone could go wrong used to abort it under
# `set -e` — leaving the contributor with no AGENTS.md, no CLAUDE.md and no doctor.sh at all,
# over a repository they may not even need. So every case below asserts the same two things:
# the run exits 0, and the three workspace files are there.
#
# The second half is about where a clone is allowed to land. A location the workspace does not
# own — an absolute path from the first developer's machine, or one reaching out with `..` —
# used to be cloned into verbatim, which put a repository outside the workspace silently
# whenever the path happened to be writable. Those cases assert the absence of a clone, not
# just the presence of a message.
#
# Assertions read the output as well as the exit status: after this change almost everything
# exits 0, so a test that only looked at $? could not tell a clone from a refusal.

set -uo pipefail
export LC_ALL=C
# A contributor who cannot reach a remote must fail fast rather than block on a credential
# prompt. The unreachable-remote fixtures below would otherwise hang.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-setup-workspace-test.XXXXXX")"
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

# bootstrap NAME LAYOUT LICENSE — generate a project and echo its workspace root. Never an
# all-default configuration: a fixture that always picks the same license is how a hardcoded
# example row survived three review passes in an earlier line of this work.
bootstrap() {
  local name="$1" layout="$2" license="$3"
  local work="$TMP_ROOT/$name"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Workspace setup resilience test" \
      --license="$license" \
      --holder="Throughstone Test" \
      --layout="$layout" \
      --collab=team \
      --remotes=no
  ) >"$TMP_ROOT/$name.init.out" 2>&1 || {
    bad "$name: init.sh failed"
    sed -n '1,40p' "$TMP_ROOT/$name.init.out" >&2
    return 1
  }
  printf '%s\n' "$work"
}

# teammate LABEL DOCS_SRC — build the workspace a second developer actually starts from: the
# docs hub cloned by hand into Code/<project>-docs/, and nothing else. Every pointer file is
# absent, which is what makes "the workspace was assembled" a real assertion rather than a
# statement about files the fixture already had.
teammate() {
  local label="$1" docs_src="$2"
  local tw="$TMP_ROOT/tw-$label"
  rm -rf "$tw"
  mkdir -p "$tw/Code"
  cp -R "$docs_src" "$tw/Code/$(basename "$docs_src")"
  printf '%s\n' "$tw"
}

registry_of() { set -- "$1"/Code/*-docs/registries/repos.yml; printf '%s\n' "$1"; }
setup_of()    { set -- "$1"/Code/*-docs/scripts/setup-workspace.sh; printf '%s\n' "$1"; }
doctor_of()   { set -- "$1"/Code/*-docs/scripts/check.sh; printf '%s\n' "$1"; }

# add_row TW — append a registry row, read from stdin, to a teammate workspace's registry.
add_row() { cat >> "$(registry_of "$1")"; }

# run_setup TW — run the workspace setup from the workspace root, capturing output and status
# in the globals SETUP_OUT / SETUP_STATUS.
run_setup() {
  local tw="$1" script
  script="$(setup_of "$tw")"
  SETUP_OUT="$(cd "$tw" && "$script" 2>&1)"
  SETUP_STATUS=$?
}

# assert_assembled LABEL TW — the guarantee the whole script exists to provide.
assert_assembled() {
  local label="$1" tw="$2" f
  [ "$SETUP_STATUS" -eq 0 ] || bad "$label: expected exit 0, got $SETUP_STATUS"
  for f in AGENTS.md CLAUDE.md doctor.sh; do
    [ -e "$tw/$f" ] || bad "$label: the workspace has no $f"
  done
  [ -x "$tw/doctor.sh" ] || bad "$label: doctor.sh is not executable"
  # Present is not the same as useful. The closing paragraph of the root pointers is what turns
  # "Read AGENTS.md and follow it" into an instruction rather than a filename, and it is what
  # init.sh leaves at the root for the person who created the project. A contributor assembling
  # their own machine reads the same file first and needs the same paragraph.
  for f in AGENTS.md CLAUDE.md; do
    grep -q "kickoff" "$tw/$f" || bad "$label: $f carries no first-action handoff paragraph"
  done
}

assert_out() {
  case "$SETUP_OUT" in
    *"$2"*) ;;
    *) bad "$1: output does not mention: $2" ;;
  esac
}
assert_not_out() {
  case "$SETUP_OUT" in
    *"$2"*) bad "$1: output should not mention: $2" ;;
  esac
}
# A .git directory does not prove a clone arrived. git exits 0 after cloning a remote whose HEAD
# names a branch that does not exist, and leaves an empty working tree behind; every assertion
# here would still have passed. Requiring HEAD to resolve is what separates a repository that
# arrived from a directory that was created.
assert_cloned() {
  [ -d "$2/.git" ] || { bad "$1: expected a clone at $2"; return; }
  git -C "$2" rev-parse --verify HEAD >/dev/null 2>&1 \
    || bad "$1: $2 has a .git but nothing checked out"
}
assert_not_cloned() {
  [ -e "$2" ] && bad "$1: nothing should have been written to $2"
}

# A real, local, cloneable remote. Without one, "the clone was refused" and "the clone failed"
# look identical, and the out-of-workspace cases below are exactly about a clone that would
# otherwise have succeeded.
# -b main, because the seed below pushes main: a bare repo initialized without it points HEAD at
# a branch nobody ever creates, and then every clone of it succeeds with nothing checked out.
REACHABLE="$TMP_ROOT/reachable.git"
git init -q --bare -b main "$REACHABLE"
seed="$TMP_ROOT/seed"
mkdir -p "$seed"
(
  cd "$seed"
  git init -q
  printf 'seed\n' > README.md
  git add -A
  git -c user.email=test@example.com -c user.name=Test commit -qm "seed"
  git branch -M main
  git push -q "$REACHABLE" main
) >/dev/null 2>&1 || bad "fixture: could not prepare the reachable remote"

UNREACHABLE="git@setup-workspace-test.invalid:team/partner-billing.git"

echo "Generating projects in both layouts ..."
multi="$(bootstrap multi multi apache-2.0)" || exit 1
mono="$(bootstrap mono mono bsd-3)" || exit 1
MULTI_DOCS="$multi/Code/multi-docs"
MONO_DOCS="$mono/Code/mono-docs"
note "multi: $MULTI_DOCS"
note "mono:  $MONO_DOCS"

# --- Part 1. A clone that cannot happen never costs the contributor the workspace -----------

echo "A repo whose remote nobody can reach ..."
tw="$(teammate unreachable "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "partner-billing"
    location: "Code/partner-billing/"
    type: service
    origin: adopted
    control: external
    remote: "$UNREACHABLE"
    description: "A repo this contributor cannot reach."
EOF
run_setup "$tw"
assert_assembled "unreachable remote" "$tw"
assert_out "unreachable remote" "warning: could not clone"
assert_out "unreachable remote" "did not arrive"

echo "Something that is not a git checkout already sitting at the location ..."
tw="$(teammate occupied "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "A slot a stray folder already occupies."
EOF
mkdir -p "$tw/Code/multi-api"
printf 'stray\n' > "$tw/Code/multi-api/notes.txt"
run_setup "$tw"
assert_assembled "occupied location" "$tw"
assert_out "occupied location" "warning: could not clone"

echo "A registry the parser cannot read ..."
tw="$(teammate unreadable "$MULTI_DOCS")"
chmod 000 "$(registry_of "$tw")"
run_setup "$tw"
chmod 644 "$(registry_of "$tw")"
assert_assembled "unreadable registry" "$tw"

echo "A project with no registries/ at all ..."
tw="$(teammate noregistry "$MULTI_DOCS")"
rm -rf "$tw"/Code/*-docs/registries
run_setup "$tw"
assert_assembled "no registries/" "$tw"
assert_out "no registries/" "skipping clone step"

# --- Part 2. A clone only ever lands where the workspace can own it -------------------------

echo "An absolute location left over from the first developer's machine ..."
tw="$(teammate absolute "$MULTI_DOCS")"
outside="$TMP_ROOT/outside-the-workspace/partner-billing"
rm -rf "$TMP_ROOT/outside-the-workspace"
add_row "$tw" <<EOF

  - name: "partner-billing"
    location: "$outside"
    type: service
    origin: adopted
    control: managed
    remote: "$REACHABLE"
    description: "An absolute path, with a remote that really does work."
EOF
run_setup "$tw"
assert_assembled "absolute location" "$tw"
assert_out "absolute location" "outside the workspace root"
assert_not_out "absolute location" "cloning $REACHABLE -> $outside"
assert_out "absolute location" "did not arrive"
assert_not_cloned "absolute location" "$outside"

echo "A location reaching out of the workspace with .. ..."
tw="$(teammate dotdot "$MULTI_DOCS")"
escaped="$TMP_ROOT/tw-dotdot-escaped"
rm -rf "$escaped"
add_row "$tw" <<EOF

  - name: "escaper"
    location: "../tw-dotdot-escaped/"
    type: service
    origin: adopted
    control: managed
    remote: "$REACHABLE"
    description: "A relative path that leaves the workspace."
EOF
run_setup "$tw"
assert_assembled "dotdot location" "$tw"
assert_out "dotdot location" "outside the workspace root"
assert_out "dotdot location" "did not arrive"
assert_not_cloned "dotdot location" "$escaped"

echo "A repo already checked out at an absolute location is left alone, not reported missing ..."
tw="$(teammate inplace "$MULTI_DOCS")"
inplace="$TMP_ROOT/in-place-repo"
rm -rf "$inplace"
git clone -q "$REACHABLE" "$inplace" >/dev/null 2>&1
add_row "$tw" <<EOF

  - name: "partner-billing"
    location: "$inplace"
    type: service
    origin: adopted
    control: managed
    remote: "$REACHABLE"
    description: "Registered in place, and really there."
EOF
run_setup "$tw"
assert_assembled "in-place repo" "$tw"
assert_out "in-place repo" "exists: $inplace"
assert_not_out "in-place repo" "outside the workspace root"
assert_not_out "in-place repo" "did not arrive"

echo "A location outside Code/ but inside the workspace is still cloned ..."
tw="$(teammate vendored "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "partner-lib"
    location: "vendor/partner-lib/"
    type: library
    origin: adopted
    control: managed
    remote: "$REACHABLE"
    description: "Outside the Code/* shell, inside the workspace root."
EOF
run_setup "$tw"
assert_assembled "vendored location" "$tw"
assert_cloned "vendored location" "$tw/vendor/partner-lib"
assert_not_out "vendored location" "did not arrive"

# --- Part 3. The ordinary paths still work --------------------------------------------------

echo "The happy path, a re-run over it, and a location containing a space ..."
tw="$(teammate happy "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "An ordinary sibling repo."

  - name: "multi web"
    location: "Code/multi web/"
    type: app
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "A location with a space in it."
EOF
run_setup "$tw"
assert_assembled "happy path" "$tw"
assert_cloned "happy path" "$tw/Code/multi-api"
assert_cloned "space in location" "$tw/Code/multi web"
assert_not_out "happy path" "did not arrive"

run_setup "$tw"
assert_assembled "re-run" "$tw"
assert_out "re-run" "exists: Code/multi-api/"
assert_not_out "re-run" "did not arrive"

echo "A registered checkout whose .git is a FILE — a linked worktree ..."
# A submodule and a linked worktree are both real repositories, and both present .git as a file
# rather than a directory; check.sh reads them as repositories for exactly that reason. When this
# script tested for a directory it disagreed with the doctor about the same row: it tried to clone
# over a checkout that was already there, and counted the repo missing when git refused.
tw="$(teammate worktree "$MULTI_DOCS")"
git init -q "$tw/Code/wt-origin" >/dev/null 2>&1
git -C "$tw/Code/wt-origin" commit -q --allow-empty -m seed
git -C "$tw/Code/wt-origin" worktree add -q "$tw/Code/multi-api" -b wtbranch
[ -f "$tw/Code/multi-api/.git" ] \
  || bad "fixture is not exercising the shape it claims: Code/multi-api/.git is not a file"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "Supplied by hand as a linked worktree, then picked up by a re-run."
EOF
run_setup "$tw"
assert_assembled "linked worktree" "$tw"
assert_out "linked worktree" "exists: Code/multi-api/"
assert_not_out "linked worktree" "did not arrive"
assert_not_out "linked worktree" "could not clone"

echo "An initialized submodule, the other shape whose .git is a file ..."
# The -e fix was justified by two shapes and only ever tested one. A submodule has to be left
# where it lives: moved out of its parent, its .git pointer no longer resolves and it stops being
# a repository, which is the next case rather than this one.
tw="$(teammate submodule "$MULTI_DOCS")"
git init -q -b main "$tw/Code/sub-origin" >/dev/null 2>&1
git -C "$tw/Code/sub-origin" commit -q --allow-empty -m seed
git init -q -b main "$tw/Code/parent" >/dev/null 2>&1
git -C "$tw/Code/parent" commit -q --allow-empty -m seed
git -C "$tw/Code/parent" -c protocol.file.allow=always \
  submodule add -q "$tw/Code/sub-origin" vendored >/dev/null 2>&1
[ -f "$tw/Code/parent/vendored/.git" ] \
  || bad "fixture is not exercising the shape it claims: the submodule .git is not a file"
add_row "$tw" <<EOF

  - name: "vendored"
    location: "Code/parent/vendored/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
EOF
run_setup "$tw"
assert_assembled "submodule" "$tw"
assert_out "submodule" "exists: Code/parent/vendored/"
assert_not_out "submodule" "did not arrive"

echo "A .git file left behind by a worktree that no longer exists ..."
# A .git file proves a repository was here once, not that one is: a linked worktree that was moved
# or deleted leaves its pointer behind. Counted as a checkout, that skipped the clone and reported
# nothing at all, so the workspace was quietly incomplete — the silent version of exactly the
# failure the old directory test produced loudly.
tw="$(teammate stalegit "$MULTI_DOCS")"
mkdir -p "$tw/Code/multi-api"
printf 'gitdir: %s\n' "$TMP_ROOT/no-such-worktree" > "$tw/Code/multi-api/.git"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
EOF
run_setup "$tw"
assert_assembled "stale .git" "$tw"
assert_not_out "stale .git" "exists: Code/multi-api/"
assert_out "stale .git" "did not arrive"

echo "The doctor and the clone loop read location:/remote: the same way ..."
# The failure neither script can report on its own: check.sh passes a file that the clone loop
# then reads differently, so the doctor says the registry is fine and the repository lands
# somewhere else — silently, at exit 0, when the wrong path happens to be writable. Both now read
# a scalar with the same function, and this is where that is held to account: one table of shapes,
# every one of them ordinary YAML, run through both readers at once. The doctor must pass the file
# and the clone must arrive at the path YAML *says* the value is — not merely the same path both
# readers happen to derive, which is a weaker property that a shared misreading satisfies.
tw="$(teammate agree "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "q-plain"
    location: "Code/q-plain/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"

  - name: "u-plain"
    location: Code/u-plain
    type: service
    origin: created
    control: managed
    remote: $REACHABLE

  - name: "sq-plain"
    location: 'Code/sq-plain'
    type: service
    origin: created
    control: managed
    remote: '$REACHABLE'

  - name: "q-comment"
    location: "Code/q-comment/" # the checkout on this machine
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"   # team mode: setup-workspace.sh clones this

  - name: "u-comment"
    location: Code/u-comment # the checkout on this machine
    type: service
    origin: created
    control: managed
    remote: $REACHABLE # team mode

  - name: "sq-comment"
    location: 'Code/sq-comment' # the checkout on this machine
    type: service
    origin: created
    control: managed
    remote: '$REACHABLE' # team mode

  - name: "hash-in-path"
    location: "Code/hash # inside"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"

  - name: "apostrophe"
    location: 'Code/apos''trophe'
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"

  - name: "brace-path"
    location: Code/{braced}-api # the checkout on this machine
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"

  - name: "escaped-backslash"
    location: "Code/escaped\\\\backslash"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
EOF
# The heredoc above is unquoted, so it needs four backslashes to write two. Two in the file is
# one directory-name backslash in YAML, which is the whole point of the row.
grep -Fq 'Code/escaped\\backslash' "$(registry_of "$tw")" \
  || bad "fixture is not exercising the shape it claims: the location carries no escape"

# The doctor half: this file is legal, and saying so is half the agreement.
doc_out="$(bash "$(doctor_of "$tw")" 2>&1)"; doc_status=$?
case "$doc_out" in
  *"[FAIL]"*) bad "reader agreement: the doctor fails a registry of ordinary YAML values" ;;
esac
[ "$doc_status" -eq 0 ] || bad "reader agreement: doctor expected exit 0, got $doc_status"

# The clone half: each value resolves to the path YAML says it is, quotes and comments removed,
# and a quoted hash kept because there it is part of the path rather than the start of a comment.
run_setup "$tw"
assert_assembled "reader agreement" "$tw"
for d in q-plain u-plain sq-plain q-comment u-comment sq-comment; do
  assert_cloned "reader agreement ($d)" "$tw/Code/$d"
done
assert_cloned "reader agreement (quoted hash)" "$tw/Code/hash # inside"
# Agreement is not correctness, and this row is why the distinction is in the fixture. A doubled
# quote inside a single-quoted YAML scalar is one literal character; reading the value by stopping
# at the first quote truncated it, and because both readers shared that reading they agreed on the
# wrong path and every assertion above still passed.
assert_cloned "reader agreement (escaped apostrophe)" "$tw/Code/apos'trophe"
assert_not_cloned "reader agreement (truncated at the escape)" "$tw/Code/apos"
assert_not_out "reader agreement" "did not arrive"
# The directories the naive reading actually produced, named so a regression cannot pass quietly:
# a single-quoted value made a top-level folder called `Code, and a commented one carried the
# comment into the path.
assert_not_cloned "reader agreement (single quotes taken literally)" "$tw/'Code"
assert_not_cloned "reader agreement (comment taken into the path)" \
  "$tw/Code/u-comment # the checkout on this machine"
# The same comment, kept for the same wrong reason one layer down: clean() left a comment on any
# value holding a brace anywhere, which is the flow-mapping exemption reaching a path. Rule 2
# welcomes a comment on location:, and nothing excludes a brace from a directory name, so both
# readers agreed on a path YAML does not name and check 13 saw nothing to report.
assert_cloned "reader agreement (brace in an unquoted path)" "$tw/Code/{braced}-api"
assert_not_cloned "reader agreement (comment kept beside a brace)" \
  "$tw/Code/{braced}-api # the checkout on this machine"
# In a double-quoted YAML scalar a backslash escapes what follows it, so the two in the file are
# one in the path. Copying both through was the same trade as the apostrophe above: the doctor and
# the clone loop agreed, and agreed on a directory YAML does not name.
assert_cloned "reader agreement (escaped backslash)" "$tw/Code/escaped\\backslash"
assert_not_cloned "reader agreement (both backslashes copied through)" "$tw/Code/escaped\\\\backslash"

echo "A target directory that exists but is empty ..."
tw="$(teammate emptydir "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "An empty slot waiting for the clone."
EOF
mkdir -p "$tw/Code/multi-api"
run_setup "$tw"
assert_assembled "empty target dir" "$tw"
assert_cloned "empty target dir" "$tw/Code/multi-api"

# The mono layout's registry is a different shape — it carries a row whose location is `.`, the
# workspace root itself, plus rows for folders inside that one repository. It is exercised here
# for the parser's sake only: collaboration.md §9 tells a mono project not to run this script,
# and this fixture is a multi-repo workspace root holding a mono project's registry.
echo "The registry a mono project generates ..."
tw="$(teammate monoshape "$MONO_DOCS")"
run_setup "$tw"
assert_assembled "mono registry" "$tw"
assert_not_out "mono registry" "did not arrive"

echo "A mono root row that has been given a remote ..."
tw="$(teammate monoroot "$MONO_DOCS")"
add_row "$tw" <<EOF

  - name: "extra-root"
    location: "."
    type: mono
    origin: created
    control: managed
    remote: "$REACHABLE"
    description: "The workspace root, which is never an empty clone target."
EOF
run_setup "$tw"
assert_assembled "mono root with a remote" "$tw"
assert_out "mono root with a remote" "warning: could not clone"

echo "A real mono checkout: the script recognises it and writes nothing ..."
# The two cases above use a teammate fixture whose root is not a repository, so they exercise the
# mono *registry* rather than a mono workspace. This is the workspace itself: init.sh made the
# root a repo and committed the pointers into it, which is what made running this script there
# destructive rather than merely pointless — three tracked files rewritten, and "Done" printed
# over the top of it.
tw="$TMP_ROOT/tw-monoreal"
rm -rf "$tw"
cp -R "$mono" "$tw"
[ -d "$tw/.git" ] \
  || bad "fixture is not exercising the shape it claims: the mono workspace root is not a repo"
[ -z "$(git -C "$tw" status --porcelain)" ] \
  || bad "fixture: the mono checkout is already dirty before the run"
run_setup "$tw"
[ "$SETUP_STATUS" -eq 0 ] || bad "mono checkout: expected exit 0, got $SETUP_STATUS"
assert_out     "mono checkout" "mono-repo-for-now"
assert_not_out "mono checkout" "Writing per-machine pointers"
assert_not_out "mono checkout" "Cloning sibling repos"
# The assertion that matters: a committed file is not touched, so there is nothing to commit by
# accident afterwards.
[ -z "$(git -C "$tw" status --porcelain)" ] \
  || bad "mono checkout: the run modified tracked files: $(git -C "$tw" status --porcelain | tr '\n' ' ')"

if [ "$failures" -eq 0 ]; then
  printf 'PASS: setup-workspace.sh assembles the workspace in every measured failure shape\n'
  exit 0
fi
printf 'FAILED: %d assertion(s)\n' "$failures" >&2
exit 1
