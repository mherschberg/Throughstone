#!/usr/bin/env bash
#
# Regression coverage for scripts/check.sh's repo-registry checks (11, 12, 13) — the doctor's
# first test of its own.
#
# Two halves. The first bootstraps real projects in both layouts and proves the checks are
# inert on a project the method just created: a greenfield registry must stay silent, or the
# checks would be reporting on every project from the day they ship. The second mutates that
# generated registry one defect at a time and proves each finding fires, and fires for its own
# reason — an assertion that cannot fail looks exactly like one that works.
#
# Assertions read the summary line, not just the exit status: a WARN does not change the exit
# code, so a test that only looked at $? could not see checks 12's findings at all.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-repo-test.XXXXXX")"
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
      --desc="Repo control check test" \
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

# doctor WORK — run the generated project's doctor, capturing output and exit status in the
# globals DOC_OUT / DOC_STATUS.
doctor() {
  DOC_OUT="$(bash "$(doctor_of "$1")" 2>&1)"
  DOC_STATUS=$?
}

# reg_rows WORK — replace everything below `repos:` with rows read from stdin, leaving the
# schema header (and its reserved- lines) exactly as shipped.
reg_rows() {
  local reg tmp
  reg="$(registry_of "$1")"
  tmp="$TMP_ROOT/reg.tmp"
  awk '{ print } /^repos:/ { exit }' "$reg" > "$tmp"
  cat >> "$tmp"
  mv "$tmp" "$reg"
}

has()     { case "$DOC_OUT" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect()  { has "$1" || bad "$2 — expected output to contain: $1"; }
refute()  { has "$1" && bad "$2 — output should NOT contain: $1"; return 0; }

# case_fires WORK LABEL EXPECTED — mutate, run, and require the finding plus a failing summary.
case_fires() {
  local work="$1" label="$2" expected="$3"
  doctor "$work"
  expect "$expected" "$label"
  expect "RESULT: FAIL" "$label"
  [ "$DOC_STATUS" -eq 1 ] || bad "$label — expected exit 1, got $DOC_STATUS"
}

# --- 1. Greenfield is silent, in both layouts --------------------------------
# The checks must be inert on a project the method just created, or they report on every
# project from the day they ship. Both layouts, because the seeded registry differs between
# them: mono carries a workspace-root row whose location IS a work-tree root.
for spec in "greenfield-multi multi apache-2.0" "greenfield-mono mono bsd-3"; do
  set -- $spec
  name="$1" layout="$2" license="$3"
  work="$(bootstrap "$name" "$layout" "$license")" || continue
  doctor "$work"
  note "$name: $(printf '%s\n' "$DOC_OUT" | grep -E '^  [0-9]+ fail')"
  expect "11. Repo registry record consistency" "$name"
  expect "12. Repo registry control record" "$name"
  expect "13. Repo registry file shape" "$name"
  expect "row(s) consistent: statuses, control/gap invariants" "$name"
  expect "carry a complete control record" "$name"
  expect "parser rules hold" "$name"
  # The guard against an assertion that cannot fail: a clean project must show none of the
  # findings the rest of this file goes on to provoke.
  refute "[FAIL]" "$name"
  refute "carry no control record" "$name"
  [ "$DOC_STATUS" -eq 0 ] || bad "$name — clean project should exit 0, got $DOC_STATUS"
done

# The mono workspace-root row is the first row the disk check meets in the commonest generated
# layout: it IS a work-tree root, and it must still owe no provides: because it is origin:
# created. Measured here rather than assumed.
mono="$TMP_ROOT/greenfield-mono"
mono_reg="$(registry_of "$mono")"
grep -qE '^[[:space:]]*location:[[:space:]]*"\."' "$mono_reg" \
  || bad "mono registry has no workspace-root row (location: \".\")"
[ -e "$mono/.git" ] || bad "mono workspace root is not a repository"
doctor "$mono"
refute "greenfield-mono ->" "mono root row"

# --- 2. Check 11 — the record contradicts itself ------------------------------
work="$(bootstrap "record-checks" multi mit)" || exit 1

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: adopted
    control: managed
    description: "Order intake."
    provides:
      readme:  { status: ours,   note: "" }
      license: { status: theirs, note: "org-wide LICENSE in acme-platform" }
      ci:      { status: gap,    note: "no pipeline yet" }
EOF
case_fires "$work" "managed + gap" "control: managed with a gap in ci"

reg_rows "$work" <<'EOF'
  - name: "partner-billing"
    location: "Code/partner-billing/"
    type: service
    origin: adopted
    control: external
    description: "Partner billing."
    provides:
      readme:  { status: extended, note: "added a Role section" }
      license: { status: theirs,   note: "their own LICENSE" }
      ci:      { status: theirs,   note: "their Buildkite pipeline" }
EOF
case_fires "$work" "external + extended" "control: external with extended in readme"

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: adopted
    control: external
    description: "Order intake."
    provides:
      readme:  { status: theirs, note: "their README" }
      license: { status: gap,    note: "" }
      ci:      { status: N/A,    note: "" }
EOF
doctor "$work"
expect "provides: license is gap and carries no note saying why" "gap needs a note"
expect "provides: ci is N/A and carries no note saying why" "N/A needs a note"
expect "RESULT: FAIL" "notes required"

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: creatd
    control: manged
    description: "Order intake."
    provides:
      readme:  { status: mine, note: "" }
      license: { status: ours, note: "" }
      ci:      { status: ours, note: "" }
EOF
doctor "$work"
# A mistyped control: is neither absent nor external, so without this it would slip past both
# invariant checks and read as controlled to anyone skimming the file.
expect 'origin: "creatd" is not created or adopted' "origin closed set"
expect 'control: "manged" is not managed or external' "control closed set"
expect 'provides: readme status "mine" is not ours/extended/theirs/N/A/gap' "status closed set"
expect "RESULT: FAIL" "closed sets"

# --- 3. Check 13 — the file is shaped so a reader would misread it -----------
# The measured exploit: a note written across lines whose text begins with a row-level field
# name. setup-workspace.sh's clone loop resolves that line as the row's location and clones
# into it, exit 0, no warning.
reg_rows "$work" <<'EOF'
  - name: "acme-docs"
    location: "Code/acme-docs/"
    type: docs
    origin: created
    control: managed
    remote: "git@example.com:acme/docs.git"
    description: |
      the org LICENSE lives at
      location: /srv/acme/LICENSE
      and covers this repo
EOF
doctor "$work"
expect "nested location: shadows a row-level field name" "rule 1 exploit"
expect "description: opens a block scalar; values are single-line" "rule 2 block scalar"
expect "not a single-line key: value" "rule 2 continuation line"
expect "RESULT: FAIL" "rule 1 + 2"
# Rule 2 is what makes rule 1 unreachable, so both must speak, not just the symptom.
[ "$DOC_STATUS" -eq 1 ] || bad "exploit — expected exit 1, got $DOC_STATUS"

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: created
    control: managed
    owner: "platform-team"
    provides:
      readme:
        status: ours
      docs:    { status: ours, note: "" }
EOF
doctor "$work"
expect "provides: readme is not a flow mapping" "rule 2 flow mapping"
expect "row-level field owner: is not in reserved-row-level" "rule 4 unknown row field"
expect "nested key docs: is not in reserved-nested" "rule 4 unknown nested key"
expect "RESULT: FAIL" "rules 2 + 4"

# The same rule one level down: a block scalar opened inside provenance:, where no
# flow-mapping rule would catch it and only the opener names the line to fix.
reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: created
    control: managed
    provenance:
      from: |
        acme-web
      split_on: "2026-01-31"
EOF
doctor "$work"
expect "from: opens a block scalar; values are single-line" "rule 2 nested block scalar"
expect "RESULT: FAIL" "rule 2 nested"

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: created
    control: managed
    location: "Code/somewhere-else/"
EOF
case_fires "$work" "duplicate field" "a second row-level location: in the same row block"

# The same exploit reached by dedenting instead of nesting. setup-workspace.sh matches line
# prefixes at any indent, so a location: at column 0 below the last row is still read as that
# row's location — a check that stopped at the block boundary would never see it.
reg_rows "$work" <<'EOF'
  - name: "acme-docs"
    location: "Code/acme-docs/"
    type: docs
    origin: created
    control: managed
    remote: "git@example.com:acme/docs.git"
location: /srv/acme/LICENSE
EOF
case_fires "$work" "dedented field" "location: sits outside any row block and would still be read as that row"

# The reserved sets are the registry header's own two lines. Overlapping them, or removing
# them, must fail loudly — otherwise editing the header silently disarms rules 1 and 4.
reg="$(registry_of "$work")"
cp "$reg" "$TMP_ROOT/reg.good"
reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: created
    control: managed
EOF
cp "$(registry_of "$work")" "$TMP_ROOT/reg.rows"

sed 's/^#\([[:space:]]*\)reserved-nested: /#\1reserved-nested: location /' \
  "$TMP_ROOT/reg.rows" > "$reg"
case_fires "$work" "overlapping reserved sets" "reserved-row-level and reserved-nested share name(s): location"

grep -v 'reserved-row-level:' "$TMP_ROOT/reg.rows" > "$reg"
case_fires "$work" "reserved line removed" "the reserved name sets cannot be read"

# --- 4. Check 12 — the control record, and what counts as a repository -------
cp "$TMP_ROOT/reg.rows" "$reg"
mkdir -p "$work/Code/acme-api" "$work/Code/plain"
git -C "$work/Code/acme-api" init -q
git -C "$work/Code/acme-api" commit -q --allow-empty -m seed
mkdir -p "$work/Code/acme-api/sub"

reg_rows "$work" <<'EOF'
  - name: "acme-api"
    location: "Code/acme-api/"
    type: service
    origin: adopted
    control: managed
    provides:
      license: { status: theirs, note: "org-wide LICENSE" }

  - name: "acme-sub"
    location: "Code/acme-api/sub/"
    type: library
    origin: adopted
    control: managed

  - name: "acme-plain"
    location: "Code/plain/"
    type: docs
    description: "a folder, not a repo yet"

  - name: "not-here"
    location: "Code/not-here/"
    type: service
    origin: adopted
    control: managed
EOF
doctor "$work"
# Named per key, not per row: the register action leaves a key out on purpose when it could
# not look, and a check written over the block alone would pass that row silently.
expect "acme-api -> provides: no readme; provides: no ci" "per-key naming"
# A directory inside a repository is not a repository, so nothing is owed for it.
refute "acme-sub ->" "subdirectory owes nothing"
# A plain folder owes no provides:, but every row owes origin: and control:.
expect "acme-plain -> no origin:; no control:" "row-level fields always owed"
# Silence about a row that could not be checked is indistinguishable from a pass.
expect "row(s) not present on this machine; provides: not checked there" "absent rows counted"
# A warning must not change the exit code — which is why these assertions read the summary.
expect "RESULT: OK" "warnings do not fail the run"
[ "$DOC_STATUS" -eq 0 ] || bad "control record warnings — expected exit 0, got $DOC_STATUS"
# The warn must never claim the project is old: nothing on disk records the installed version.
refute "this project is old" "no age claim"

# A submodule and a linked worktree both present .git as a FILE and both are real repositories,
# which is why the check compares work-tree roots rather than testing for a .git directory.
git -C "$work/Code/acme-api" worktree add -q "$work/Code/wt" -b wtbranch
mkdir -p "$work/Code/parent"
git -C "$work/Code/parent" init -q
git -C "$work/Code/parent" commit -q --allow-empty -m seed
git -C "$work/Code/parent" -c protocol.file.allow=always \
  submodule add -q "$work/Code/acme-api" vendor/lib >/dev/null 2>&1
for f in "$work/Code/wt/.git" "$work/Code/parent/vendor/lib/.git"; do
  [ -f "$f" ] || bad "fixture is not exercising the shape it claims: $f is not a file"
done
reg_rows "$work" <<'EOF'
  - name: "linked-worktree"
    location: "Code/wt/"
    type: service
    origin: adopted
    control: managed

  - name: "submodule"
    location: "Code/parent/vendor/lib/"
    type: library
    origin: adopted
    control: managed
EOF
doctor "$work"
expect "linked-worktree -> provides: no readme" "linked worktree is a repository"
expect "submodule -> provides: no readme" "submodule is a repository"

# A repo the method created carries no observation debt, so the same work trees stay silent
# once their rows say origin: created. This is what keeps the check greenfield-inert.
reg_rows "$work" <<'EOF'
  - name: "linked-worktree"
    location: "Code/wt/"
    type: service
    origin: created
    control: managed

  - name: "submodule"
    location: "Code/parent/vendor/lib/"
    type: library
    origin: created
    control: managed
EOF
doctor "$work"
refute "provides: no readme" "created rows owe no provides"
expect "RESULT: OK" "created rows are clean"

# --- 5. No registry at all ----------------------------------------------------
# Pre-1.8 projects bootstrapped with --registries=no have no file. That is reported once,
# rather than three times or not at all.
mv "$reg" "$TMP_ROOT/reg.away"
doctor "$work"
expect "no registries/repos.yml — skipping repo registry checks" "missing registry warns once"
expect "nothing to check (reported in check 11)" "missing registry is not silent"
expect "RESULT: OK" "missing registry does not fail the run"
mv "$TMP_ROOT/reg.away" "$reg"

if [ "$failures" -ne 0 ]; then
  printf 'check.sh repo-registry checks: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
echo "check.sh repo-registry checks: PASS"
