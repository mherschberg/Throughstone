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
assert_cloned() {
  [ -d "$2/.git" ] || bad "$1: expected a clone at $2"
}
assert_not_cloned() {
  [ -e "$2" ] && bad "$1: nothing should have been written to $2"
}

# A real, local, cloneable remote. Without one, "the clone was refused" and "the clone failed"
# look identical, and the out-of-workspace cases below are exactly about a clone that would
# otherwise have succeeded.
REACHABLE="$TMP_ROOT/reachable.git"
git init -q --bare "$REACHABLE"
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
    added_as: adopted
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
    added_as: created
    remote: "$REACHABLE"
    description: "A slot a stray folder already occupies."
EOF
mkdir -p "$tw/Code/multi-api"
printf 'stray\n' > "$tw/Code/multi-api/notes.txt"
run_setup "$tw"
assert_assembled "occupied location" "$tw"
assert_out "occupied location" "warning: could not clone"

# Not a clone that fails but a parse that does: awk cannot open the file at all. The clone loop
# is fed by process substitution rather than a pipe precisely so that awk's exit status stays out
# of `pipefail` — feed it by a pipe and this case takes the whole run down with it.
echo "A registry file the clone step's awk cannot read ..."
tw="$(teammate unreadable "$MULTI_DOCS")"
chmod 000 "$(registry_of "$tw")"
# chmod 000 does not stop a privileged reader, and the case would then pass having exercised
# nothing at all. Establish the precondition rather than assume it.
head -c1 "$(registry_of "$tw")" >/dev/null 2>&1 \
  && bad "unreadable registry: the fixture is still readable, so this case proved nothing"
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
    added_as: adopted
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
    added_as: adopted
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
# Uncommitted local work, so the failure that matters — the directory replaced or cleared, the
# contributor's own work gone with it — is caught as state. The `exists:` line below is printed
# by the branch that skips the clone, but a maintainer who restructures that loop could print it
# and still re-clone or clear the directory.
printf 'local work\n' > "$inplace/uncommitted.txt"
add_row "$tw" <<EOF

  - name: "partner-billing"
    location: "$inplace"
    type: service
    added_as: adopted
    remote: "$REACHABLE"
    description: "Registered in place, and really there."
EOF
run_setup "$tw"
assert_assembled "in-place repo" "$tw"
assert_out "in-place repo" "exists: $inplace"
[ -f "$inplace/uncommitted.txt" ] || bad "in-place repo: uncommitted work in the checkout is gone"
assert_not_out "in-place repo" "outside the workspace root"
assert_not_out "in-place repo" "did not arrive"

echo "A location outside Code/ but inside the workspace is still cloned ..."
tw="$(teammate vendored "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "partner-lib"
    location: "vendor/partner-lib/"
    type: library
    added_as: adopted
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
    added_as: created
    remote: "$REACHABLE"
    description: "An ordinary sibling repo."

  - name: "multi web"
    location: "Code/multi web/"
    type: app
    added_as: created
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

echo "A target directory that exists but is empty ..."
tw="$(teammate emptydir "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    added_as: created
    remote: "$REACHABLE"
    description: "An empty slot waiting for the clone."
EOF
mkdir -p "$tw/Code/multi-api"
run_setup "$tw"
assert_assembled "empty target dir" "$tw"
assert_cloned "empty target dir" "$tw/Code/multi-api"

# The mono layout's registry is a different shape — a row whose location is `.`, the workspace
# root itself, plus rows for folders inside that one repository. The parser reads it, but nothing
# it ships has a remote, so the loop body never runs: a smoke test that the shape neither crashes
# the run nor invents a missing repo. The case after appends a second `.` row, this one with a
# remote, and that is what makes a root-location row observable — through the clone it attempts.
# collaboration.md §9 tells a mono project not to run this script; the fixture is a multi-repo
# workspace root holding a mono project's registry.
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
    added_as: created
    remote: "$REACHABLE"
    description: "The workspace root, which is never an empty clone target."
EOF
run_setup "$tw"
assert_assembled "mono root with a remote" "$tw"
assert_out "mono root with a remote" "warning: could not clone"

if [ "$failures" -eq 0 ]; then
  printf 'PASS: setup-workspace.sh assembles the workspace in every measured failure shape\n'
  exit 0
fi
printf 'FAILED: %d assertion(s)\n' "$failures" >&2
exit 1
