#!/usr/bin/env bash
#
# Regression coverage for the every-run doctor checks that read rows out of a table, or templates
# out of a folder, when there is nothing there to read: scripts/check.sh's duplicate-STEP,
# duplicate-ADR, status and conditional-template checks.
#
# The defect under test is a clean PASS from a check that read nothing — an emptied STEP index or
# ADR registry, a STEP table whose Status header was renamed, a missing session-templates folder.
# So every case refutes its section's PASS as well as expecting the WARN: the WARN alone could be
# printed beside a PASS that still vouches for rows nobody read.
#
# Half of the rule is staying quiet. Some zeros are how a project starts — no ADR yet — or a
# choice a project may make — deleting the optional conditional templates — and a doctor that
# warned on those would teach people to ignore it. So the fresh project is asserted clean, with
# the row counts its pass lines print, and the deliberate deletion is asserted to pass.
#
# Findings are read out of each check's own section, found by its title rather than its number,
# with their severity marker. Every case breaks its own copy of one generated project.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-nothing-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

SLUG="inspect"
failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

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

# bootstrap — generate the project every case copies, and echo its workspace root. The checks
# under test read the same files in either layout.
bootstrap() {
  local work="$TMP_ROOT/$SLUG"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$SLUG" \
      --desc="Nothing-to-inspect check test" \
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

# fixture LABEL — a fresh copy of the generated project for one case to break. The doctor finds
# its root from its own path, so the copy is a project in its own right.
fixture() {
  cp -R "$base" "$TMP_ROOT/case-$1"
  printf '%s\n' "$TMP_ROOT/case-$1"
}

# doctor WORK — run the project's doctor. DOC_OUT is the whole run and DOC_STATUS its exit status.
doctor() {
  DOC_OUT="$(bash "$1/Code/$SLUG-docs/scripts/check.sh" 2>&1)"
  DOC_STATUS=$?
}

# look TITLE — select one check's section of the last run, from its heading to the next one, so
# a finding another check printed cannot satisfy an assertion about this one.
look() {
  SEC_TITLE="$1"
  SEC="$(printf '%s\n' "$DOC_OUT" | awk -v t="$1" '/^[0-9]+\. / || /^Summary$/ { f = (index($0, t) > 0); next } f')"
  [ -n "$SEC" ] || bad "the doctor printed no \"$1\" section, or an empty one"
}

has()    { case "$SEC" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect() { has "$1" || bad "$2 — expected \"$SEC_TITLE\" to report: $1"; }
refute() { has "$1" && bad "$2 — \"$SEC_TITLE\" should NOT report: $1"; return 0; }

# edit FILE PERL WHAT — apply a perl substitution and require that it changed the file. A pattern
# that stopped matching the generated file would leave it as it was, and the case would pass for
# the wrong reason.
edit() {
  cp "$1" "$TMP_ROOT/before"
  perl -pi -e "$2" "$1"
  cmp -s "$TMP_ROOT/before" "$1" && bad "fixture: $3 changed nothing"
  return 0
}

base="$(bootstrap)" || exit 1

# --- 1. A fresh project ---------------------------------------------------------
# Nothing is wrong, so nothing warns: one STEP row, no ADR yet, and a substep row per numbered
# session. The counts are asserted because a count is what shows a zero in a pass line, and a
# check that had stopped reading would print one. The substep count is taken from the index by
# row number rather than written down, so adding a session template does not break this case.
doctor "$base"
look "Duplicate STEP numbers"
expect "[PASS] no duplicate STEP numbers (1 STEP row(s))" "fresh project"
look "Duplicate ADR numbers"
expect "[PASS] no duplicate ADR numbers (0 ADR row(s))" "fresh project: no ADR yet passes"
subs="$(grep -cE '^\| 1\.[0-9]+ \|' "$base/prompts/STEP-index.md")"
[ "$subs" -gt 0 ] || bad "fixture: the generated index has no STEP-1 substep rows to count"
look "Statuses valid"
expect "[PASS] all statuses valid (1 STEP row(s), $subs substep row(s))" "fresh project"
case "$DOC_OUT" in
  *"0 fail(s), 0 warning(s)"*) ;;
  *) bad "fresh project — expected 0 fail(s), 0 warning(s)" ;;
esac

# --- 2. A STEP row under no Status column ---------------------------------------
# A status is found by its column header's name, so a STEP row under a header that lost it is
# never read. STEP-1 carries a bad status throughout: with the header intact the check fails on
# it, which is what shows it is the rows under a renamed header that go unread.
c="$(fixture renamed-header)"
idx="$c/prompts/STEP-index.md"
edit "$idx" 's/^(\| STEP-1 \| Architecture \| \| )Planned/${1}Bogus/' "setting STEP-1 to Bogus"
doctor "$c"
look "Statuses valid"
expect "[FAIL] invalid status value(s):" "bad status, header intact"
expect 'STEP-1 -> "Bogus"' "bad status, header intact"
refute "[PASS]" "bad status, header intact"
[ "$DOC_STATUS" -eq 1 ] || bad "bad status, header intact — expected exit 1, got $DOC_STATUS"

edit "$idx" 's/^(\| STEP \| Title \| Owner \| )Status( \|)/${1}State$2/' "renaming the STEP table's Status header"
doctor "$c"
look "Statuses valid"
expect "[WARN] read the status of 0 of 1 STEP row(s)" "renamed Status header"
expect "templates/step-index-seed.md" "renamed Status header hint"
refute "[PASS]" "renamed Status header"

# A project grows a table per phase, and a header renamed in one of them leaves the rest read. A
# count of statuses read against STEP rows present sees that; a check for zero does not.
c="$(fixture second-phase)"
cat >> "$c/prompts/STEP-index.md" <<'MD'

## Phase 2 — Later

| STEP | Title | Owner | State | Repos (projection) | Scope (one line) |
|------|-------|-------|-------|--------------------|------------------|
| STEP-2 | Later work | | Planned | | Fixture |
MD
doctor "$c"
look "Statuses valid"
expect "[WARN] read the status of 1 of 2 STEP row(s)" "renamed header in one phase table of two"
refute "[PASS]" "renamed header in one phase table of two"

# --- 3. An index with no STEP row ------------------------------------------------
# init.sh reserves STEP-1 and a STEP number is never deleted, so an index with no STEP row has
# lost it. Both checks that read the index warn, as both do when the file is deleted, and a
# warning leaves the exit code alone. The row goes first, with the rest of the file kept — its
# header, prose and substep table — so the warning is shown to key on the row and not on an
# empty file; then the file is emptied outright.
no_step_row() {
  doctor "$c"
  look "Duplicate STEP numbers"
  expect "[WARN] found no STEP rows in prompts/STEP-index.md" "$1"
  expect "a STEP row starts at the left margin" "$1 hint"
  refute "[PASS]" "$1"
  look "Statuses valid"
  expect "[WARN] found no STEP rows in prompts/STEP-index.md" "$1"
  refute "[PASS]" "$1"
  [ "$DOC_STATUS" -eq 0 ] || bad "$1 — a WARN must not change the exit code, got $DOC_STATUS"
}
c="$(fixture no-step-row)"
edit "$c/prompts/STEP-index.md" '$_ = "" if /^\| STEP-1 \|/' "deleting the STEP-1 row"
no_step_row "STEP-1 row deleted"
: > "$c/prompts/STEP-index.md"
no_step_row "emptied STEP index"

# --- 4. An ADR registry with no table --------------------------------------------
# No ADR row is also how every project starts (case 1), so the row count cannot tell the two
# apart. The registry table can: it ships with the file and stays while it is empty. The table
# goes first, with the prose around it kept, then the file is emptied outright. The control is a
# registry that lost its table but still holds a row — the check read that row, so it passes.
no_adr_table() {
  doctor "$c"
  look "Duplicate ADR numbers"
  expect "[WARN] found no ADR rows and no registry table" "$1"
  expect "| ADR | Title | Status | Date |" "$1 hint"
  refute "[PASS]" "$1"
}
c="$(fixture no-adr-table)"
adr="$c/Code/$SLUG-docs/adr/README.md"
edit "$adr" '$_ = "" if /^\|/' "deleting the ADR registry table"
no_adr_table "ADR registry table deleted"
: > "$adr"
no_adr_table "emptied ADR registry"

printf '| ADR-0001 | A decision | Accepted | 2026-01-15 |\n' > "$adr"
doctor "$c"
look "Duplicate ADR numbers"
expect "[PASS] no duplicate ADR numbers (1 ADR row(s))" "an ADR row with no table header"
refute "[WARN]" "an ADR row with no table header"

# --- 5. The session-templates folder ----------------------------------------------
# Conditional templates are optional, and a project may delete them on purpose: that passes. The
# folder they live in holds the numbered sessions too, so a missing folder warns.
sessions="Code/$SLUG-docs/templates/architecture-sessions"
c="$(fixture no-conditionals)"
rm -f "$c/$sessions"/conditional-*.md
doctor "$c"
look "Conditional-session template contract"
expect "[PASS] no conditional-session templates found (nothing to check)" "conditional templates deleted on purpose"
refute "[WARN]" "conditional templates deleted on purpose"

c="$(fixture no-sessions)"
rm -rf "${c:?}/$sessions"
doctor "$c"
look "Conditional-session template contract"
expect "[WARN] no $sessions/ folder — skipping conditional-session check" "missing session-templates folder"
refute "[PASS]" "missing session-templates folder"

if [ "$failures" -ne 0 ]; then
  printf 'check.sh nothing-to-inspect checks: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
echo "check.sh nothing-to-inspect checks: PASS"
