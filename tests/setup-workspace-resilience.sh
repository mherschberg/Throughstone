#!/usr/bin/env bash
#
# Regression coverage for scripts/setup-workspace.sh — the script every developer after the
# first runs to assemble the project on their machine.
#
# One property is under test in Parts 1 to 3: the workspace always gets assembled. It clones the
# repos the registry lists, and every measured way a clone could go wrong used to abort it under
# `set -e` — leaving the contributor with no AGENTS.md, no CLAUDE.md and no doctor.sh at all,
# over a repository they may not even need. So every one of those cases asserts the same thing:
# the run exits 0, and the workspace it left behind is one a contributor can use — the two
# Markdown pointers naming the docs hub the run itself reported, and a doctor.sh that reaches the
# dispatcher inside it. Presence was what this used to assert, and presence is satisfied by three
# zero-byte files. Part 0 is a different property riding on the same two bootstraps; it says so.
#
# The second half is about where a clone is allowed to land. A registered location is always a
# path relative to the workspace root, and one that breaks that shape used to be cloned into
# verbatim, putting a repository outside the workspace — or, for a tilde, into a literal `~`
# directory — whenever the path happened to be writable. Those cases
# assert the absence of a clone, not just the presence of a message. One case is the other side
# of the same rule: a repo that cannot move is reached through a symlink at a workspace-relative
# location, and that must still be left alone. Another is about which row a clone belongs to: a
# registry with a row the parser cannot read clones nothing, since that row's fields sit under
# the row above it.
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
#
# Presence is not that guarantee; a pointer that points somewhere is. All three of these files
# exist only to name the docs hub — the two Markdown pointers so an agent opened at the root can
# find it, doctor.sh so `./doctor.sh` reaches the dispatcher inside it — and `-e` is satisfied by
# a zero-byte file, so the run could announce a docs hub and write pointers to nothing.
#
# The two halves cover different things and neither is redundant. The pointer check compares the
# pointers against the hub the run itself announced, so it catches pointers that name no hub at
# all but not a hub path that is wrong in the announcement too. Running doctor.sh is what covers
# that: it is the only way to find out whether the path the wrapper was written with resolves.
assert_assembled() {
  local label="$1" tw="$2" f docs_rel help_out help_status
  [ "$SETUP_STATUS" -eq 0 ] || bad "$label: expected exit 0, got $SETUP_STATUS"
  for f in AGENTS.md CLAUDE.md doctor.sh; do
    [ -e "$tw/$f" ] || bad "$label: the workspace has no $f"
  done
  [ -x "$tw/doctor.sh" ] || bad "$label: doctor.sh is not executable"

  docs_rel="$(printf '%s\n' "$SETUP_OUT" | sed -n 's/^Docs hub:[[:space:]]*//p' | head -n1)"
  if [ -z "$docs_rel" ]; then
    bad "$label: the run never reported which docs hub it wrote into"
  else
    for f in AGENTS.md CLAUDE.md; do
      grep -Fq "$docs_rel/AGENTS.md" "$tw/$f" \
        || bad "$label: $f does not point at $docs_rel/AGENTS.md"
    done
  fi

  # doctor.sh is a wrapper the script writes around the docs hub's dispatcher, and running it is
  # the only way to find out whether the path it was written with resolves. `help` is the one
  # command that reaches the dispatcher without running a project check, so it costs nothing to
  # run in every case. An empty file exits 0 and prints nothing; a wrapper pointed at a hub that
  # is not there exits 1 and says so — neither can produce the dispatcher's own usage banner.
  help_out="$("$tw/doctor.sh" help 2>&1)"; help_status=$?
  if [ "$help_status" -ne 0 ]; then
    bad "$label: ./doctor.sh help exited $help_status: $help_out"
  else
    case "$help_out" in
      *"Throughstone project helper dispatcher"*) ;;
      *) bad "$label: ./doctor.sh help did not reach the dispatcher: $help_out" ;;
    esac
  fi
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

# assert_cloned LABEL DIR — a clone that arrived, not just a directory shaped like one.
# `git clone` creates .git before it writes a single working-tree file, so `[ -d .git ]` is true
# even for a clone that fetched every object and then checked nothing out — which is exactly what
# a remote whose HEAD names a branch it does not carry produces, exit 0 and all. Ask the
# repository what it holds instead of asking the filesystem: `ls-files` reads the index, which is
# empty for precisely that clone, and nothing but git can put an entry in it, so a stray file
# left at the location by an earlier case cannot satisfy this either.
assert_cloned() {
  [ -d "$2/.git" ] || { bad "$1: expected a clone at $2"; return; }
  [ -n "$(git -C "$2" ls-files)" ] || bad "$1: the clone at $2 checked out no files"
}
assert_not_cloned() {
  [ -e "$2" ] && bad "$1: nothing should have been written to $2"
}

# bare_remote PATH [BRANCH] — create a bare fixture remote whose HEAD names BRANCH (default
# `main`, which is what every fixture in this file is pushed as). `git init --bare` alone
# leaves HEAD at `init.defaultBranch`, and where that is unset — CI, and any machine nobody has
# configured — that is `refs/heads/master`: a branch the pushed content never reaches. Cloning
# such a remote still exits 0 and still creates `.git`, so a clone-based assertion passes over a
# working tree with nothing in it. Name the branch at creation, the way a real host does.
bare_remote() {
  git init --bare -q -b "${2:-main}" "$1"
}

# A real, local, cloneable remote. Without one, "the clone was refused" and "the clone failed"
# look identical, and the out-of-workspace cases below are exactly about a clone that would
# otherwise have succeeded. The seed below is pushed as `main`, which is why this one takes the
# helper's default: a bare HEAD naming anything else checks nothing out.
REACHABLE="$TMP_ROOT/reachable.git"
bare_remote "$REACHABLE"
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

# --- Part 0. The generated projects carry no unresolved template placeholders ----------------
# Not a property of setup-workspace.sh, and it is here for what the two bootstraps above already
# provide: the suite's only pair covering both layouts with a real project license stamped.
# init.sh step 3 turns {{PROJECT}} into the slug, and nothing anywhere checked that it happened.
# A project that shipped literal {{PROJECT}} in METHOD.md and the three runbook families passed
# every test in this suite and reported RESULT: OK from its own doctor.sh, while every path
# those documents tell an agent to open was wrong.
#
# The list below is what a generated project is allowed to keep: the fill-in-the-blank templates
# a human completes later, the seeded STEP index, and init.sh itself, which keeps the
# {{YEAR}}/{{HOLDER}} pair it stamps a license with. Holding it as a literal means a newly
# leaked file arrives as an added line rather than as silence, and comparing the whole set
# rather than hunting for stragglers doubles as the positive control: a grep that had quietly
# stopped seeing files comes up short here instead of passing on an empty result.
RETAINED_PLACEHOLDERS="$TMP_ROOT/placeholders-retained"
cat > "$RETAINED_PLACEHOLDERS" <<'EOF'
Code/DOCS/BOOTSTRAP-PROMPT.md
Code/DOCS/UPDATING-THROUGHSTONE.md
Code/DOCS/templates/adr-template.md
Code/DOCS/templates/architecture-doc-template.md
Code/DOCS/templates/licenses/Apache-2.0.txt
Code/DOCS/templates/licenses/BSD-3-Clause.txt
Code/DOCS/templates/licenses/MIT.txt
Code/DOCS/templates/licenses/README.md
Code/DOCS/templates/phase-readme-template.md
Code/DOCS/templates/release-notes-template.md
Code/DOCS/templates/repo-readme-template.md
Code/DOCS/templates/reports/check-in-report-template.md
Code/DOCS/templates/reports/incidents/incident-postmortem-report-template.md
Code/DOCS/templates/reports/test-results/test-results-summary-template.md
Code/DOCS/templates/step-index-seed.md
Code/DOCS/templates/step-plan-template.md
Code/DOCS/templates/substep-prompt-template.md
init.sh
prompts/STEP-index.md
EOF

# assert_no_placeholders SLUG WORK — sweep one generated workspace root. The slug doubles as the
# label: both projects are named for their layout.
assert_no_placeholders() {
  local slug="$1" work="$2"
  local leaked named actual="$TMP_ROOT/placeholders-$slug"

  # The three tokens init.sh has a value for. They have to be named rather than inferred from the
  # file list, because many of the files pinned above legitimately hold other {{ tokens: a
  # {{PROJECT}} that survived inside one of those would leave the list below entirely unchanged.
  leaked="$( cd "$work" && grep -rlF --exclude-dir=.git \
    -e '{{PROJECT}}' -e '{{PROJECT_DESCRIPTION}}' -e '{{TRUNK_BRANCH}}' . 2>/dev/null \
    | sed 's|^\./||' | sort )"
  if [ -n "$leaked" ]; then
    bad "$slug: init.sh left a token it owns unresolved in $(printf '%s\n' "$leaked" | wc -l | tr -d ' ') file(s)"
    printf '%s\n' "$leaked" >&2
  fi

  # Absence is only half of it: a substitution that resolved to NOTHING satisfies every check in
  # this function. One character in init.sh's perl expression — a mistyped %ENV key — empties
  # every token it owns and leaves a tree with no placeholder in it anywhere. So assert the value
  # arrived as well as the token leaving. The docs hub's own path is the one string every
  # generated project spells out, in its pointers, its runbooks and its registry.
  if ! ( cd "$work" && grep -rqF --exclude-dir=.git "Code/$slug-docs" . 2>/dev/null ); then
    bad "$slug: nothing names Code/$slug-docs — the {{PROJECT}} substitution resolved to nothing"
  fi

  # Every other file still holding a {{ token has to be one the project is meant to keep. The
  # docs hub is named for the slug, so normalise that one directory out of the path; without it
  # the two layouts spell the same files two different ways.
  ( cd "$work" && grep -rlF '{{' . --exclude-dir=.git 2>/dev/null ) \
    | sed -e 's|^\./||' -e "s|^Code/$slug-docs/|Code/DOCS/|" | sort > "$actual"
  diff -u "$RETAINED_PLACEHOLDERS" "$actual" \
    || bad "$slug: the files still holding a {{ token have drifted (- expected, + found)"

  # A content grep never looks at a path. The docs hub ships as the literal directory
  # Code/{{PROJECT}}-docs and is renamed at the end of step 3 — drop that one line and every file
  # inside it reads correctly while the directory holding them still says {{PROJECT}}.
  named="$( find "$work" -name .git -prune -o -name '*{{*' -print 2>/dev/null )"
  if [ -n "$named" ]; then
    bad "$slug: a generated path still contains a placeholder"
    printf '%s\n' "$named" >&2
  fi
}

echo "Sweeping both generated projects for unresolved placeholders ..."
assert_no_placeholders multi "$multi"
assert_no_placeholders mono  "$mono"

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

# --- Part 2. A clone only ever lands at a path relative to the workspace root ---------------

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
assert_out "absolute location" "a location must be a path relative to the workspace root"
assert_not_out "absolute location" "cloning $REACHABLE -> $outside"
assert_out "absolute location" "did not arrive"
assert_not_cloned "absolute location" "$outside"

# The same shape, but with a real checkout sitting at it — what a bad row looks like on the one
# machine it was written from. The existing-checkout test matches there and would report the row
# as fine, so the shape guard has to run first or that machine, the one best placed to fix the
# row, is told nothing at all. Nothing is written either way: assert the checkout is undisturbed.
echo "A prohibited location that already holds a checkout on this machine ..."
tw="$(teammate authored "$MULTI_DOCS")"
authored="$TMP_ROOT/authored-elsewhere"
rm -rf "$authored"
git clone -q "$REACHABLE" "$authored" >/dev/null 2>&1
printf 'local work\n' > "$authored/uncommitted.txt"
add_row "$tw" <<EOF

  - name: "partner-billing"
    location: "$authored"
    type: service
    added_as: adopted
    remote: "$REACHABLE"
    description: "An absolute path that really does resolve on this machine."
EOF
run_setup "$tw"
assert_assembled "authored-here location" "$tw"
assert_out "authored-here location" "a location must be a path relative to the workspace root"
assert_out "authored-here location" "did not arrive"
assert_not_out "authored-here location" "exists: $authored"
[ -f "$authored/uncommitted.txt" ] || bad "authored-here location: the checkout there was disturbed"

# A tilde is not an absolute path and does not reach out with `..`, and it is the one shape the
# workspace does not own that a run could complete "successfully": this loop reads the location
# out of a variable, where the shell performs no tilde expansion, so an unskipped tilde location
# is cloned into a literal `~` directory under the workspace root and counted as a clone that
# worked. Assert the directory is absent, not just the message.
echo "A location that starts with a tilde ..."
tw="$(teammate tilde "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "home-lib"
    location: "~/tw-tilde-lib/"
    type: library
    added_as: adopted
    remote: "$REACHABLE"
    description: "A home-relative path from the first developer's machine."
EOF
run_setup "$tw"
assert_assembled "tilde location" "$tw"
assert_out "tilde location" "a location must be a path relative to the workspace root"
assert_out "tilde location" "did not arrive"
assert_not_cloned "tilde location" "$tw/~"

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
assert_out "dotdot location" "a location must be a path relative to the workspace root"
assert_out "dotdot location" "did not arrive"
assert_not_cloned "dotdot location" "$escaped"

# The escape hatch for a repo that genuinely cannot move: it stays where it is and a symlink at
# a workspace-relative location points at it, so the row is the same on every machine. Two
# mechanics carry it — the location is contained, so it passes the shape guard on its text, and
# the existing-checkout branch reaches `.git` through the link because `-d` follows symlinks.
# The second is what this case holds: make a symlinked location stop counting as an existing
# checkout and the run tries to clone over the link instead.
# Uncommitted local work, so the failure that matters — the checkout replaced or cleared, the
# contributor's own work gone with it — is caught as state. The `exists:` line below is printed
# by the branch that skips the clone, but a maintainer who restructures that loop could print it
# and still re-clone or clear the directory.
echo "A repo that cannot move, reached through a symlink at a workspace-relative location ..."
tw="$(teammate symlink "$MULTI_DOCS")"
immovable="$TMP_ROOT/immovable-lib"
rm -rf "$immovable"
git clone -q "$REACHABLE" "$immovable" >/dev/null 2>&1
printf 'local work\n' > "$immovable/uncommitted.txt"
ln -s "$immovable" "$tw/Code/immovable-lib"
add_row "$tw" <<EOF

  - name: "immovable-lib"
    location: "Code/immovable-lib/"
    type: library
    added_as: adopted
    remote: "$REACHABLE"
    description: "A repo that cannot move, linked at a workspace-relative location."
EOF
run_setup "$tw"
assert_assembled "symlinked location" "$tw"
assert_out "symlinked location" "exists: Code/immovable-lib/"
[ -L "$tw/Code/immovable-lib" ] || bad "symlinked location: the link is gone or was replaced"
[ -f "$immovable/uncommitted.txt" ] || bad "symlinked location: uncommitted work in the real checkout is gone"
assert_not_out "symlinked location" "a location must be a path relative to the workspace root"
assert_not_out "symlinked location" "did not arrive"

# git reads a leading `-` as an option, so without the `--` in the clone the run dies with
# `unknown switch` and the repo does not arrive. Nothing else in the suite passes git a value it
# could mistake for a flag, so deleting the `--` is invisible without this case.
echo "A location that begins with a dash ..."
tw="$(teammate dash "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "dash-lib"
    location: "-dash-lib/"
    type: library
    added_as: adopted
    remote: "$REACHABLE"
    description: "A location whose first character git could read as an option."
EOF
run_setup "$tw"
assert_assembled "dash location" "$tw"
assert_cloned "dash location" "$tw/-dash-lib"
assert_not_out "dash location" "did not arrive"

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

# A row is read from its `- name:` line. This registry's second row starts on a bare `-`, so it is
# not read, and its fields overwrite the first row's: the first repo would never arrive and nothing
# would say so, and a row out of order the same way pairs one repo's remote with another's location.
# When the list's entries and the rows read disagree, nothing is cloned — assert both locations
# stay empty, not just the message.
echo "A registry row that does not start with its - name: line ..."
tw="$(teammate unreadrow "$MULTI_DOCS")"
add_row "$tw" <<EOF

  - name: "multi-api"
    location: "Code/multi-api/"
    type: service
    added_as: created
    remote: "$REACHABLE"
    description: "A row the parser reads."
  -
    name: "multi-web"
    location: "Code/multi-web/"
    type: app
    added_as: created
    remote: "$REACHABLE"
    description: "A row that starts on a bare dash."
EOF
run_setup "$tw"
assert_assembled "unread row" "$tw"
assert_out "unread row" "does not start with its - name: line"
assert_not_cloned "unread row" "$tw/Code/multi-api"
assert_not_cloned "unread row" "$tw/Code/multi-web"

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
