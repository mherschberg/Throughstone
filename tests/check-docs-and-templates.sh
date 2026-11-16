#!/usr/bin/env bash
#
# Regression coverage for the scripts/check.sh checks that read a project's documents and
# templates: check 4 (architecture docs carry Version / Status / Version Log), check 5 (the ADR
# registry and the ADR files agree, both ways), check 6 (no personal preferences left in
# overview.md) and check 8 (session templates, their headings and the STEP-index seed agree).
#
# The doctor runs in every generated project's CI, so a check that stops reporting lets every
# project pass over the files it was meant to catch. Each case breaks one thing in a copy of a
# fresh project and asserts the finding, its severity, the section's missing PASS line and the
# exit code. Findings are read out of each check's own section, found by its title.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-check-docs-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

SLUG="docs"
DOCS="Code/$SLUG-docs"
failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

# copy_template DEST — build a template fixture from HEAD, then overlay current worktree changes,
# so uncommitted edits are under test.
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

# bootstrap — generate the project the cases run on, and echo its workspace root.
bootstrap() {
  local work="$TMP_ROOT/$SLUG"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$SLUG" \
      --desc="Docs and templates check test" \
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

# fixture LABEL — a fresh copy of the generated project for one case to change.
fixture() {
  cp -R "$base" "$TMP_ROOT/case-$1"
  printf '%s\n' "$TMP_ROOT/case-$1"
}

# doctor WORK — run the project's doctor. DOC_OUT is the whole run and DOC_STATUS its exit status.
doctor() {
  DOC_OUT="$(bash "$1/$DOCS/scripts/check.sh" 2>&1)"
  DOC_STATUS=$?
}

# look TITLE — select one check's section of the last run, from its heading to the next one.
look() {
  SEC_TITLE="$1"
  SEC="$(printf '%s\n' "$DOC_OUT" | awk -v t="$1" '/^[0-9]+\. / || /^Summary$/ { f = (index($0, t) > 0); next } f')"
  [ -n "$SEC" ] || bad "the doctor printed no \"$1\" section, or an empty one"
}

has()    { case "$SEC" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
expect() { has "$1" || bad "$2 — expected \"$SEC_TITLE\" to report: $1"; }
refute() { has "$1" && bad "$2 — \"$SEC_TITLE\" should NOT report: $1"; return 0; }
status_is() { [ "$DOC_STATUS" -eq "$1" ] || bad "$2 — expected exit $1, got $DOC_STATUS"; }

# edit FILE PERL WHAT — apply a perl substitution and require that it changed the file, so a
# pattern that no longer matches cannot pass a case by leaving the file as it was.
edit() {
  cp "$1" "$TMP_ROOT/before"
  perl -pi -e "$2" "$1"
  cmp -s "$TMP_ROOT/before" "$1" && bad "fixture: $3 changed nothing"
  return 0
}

ARCH="Architecture docs carry"
ADR="ADR registry matches ADR files"
LEGACY="Legacy local user profile fields"
NUMBERING="Architecture-session template numbering"

base="$(bootstrap)" || exit 1

# --- 1. A fresh project -----------------------------------------------------------
# Every later case expects its section's PASS line to be gone, so first show each one is printed.
doctor "$base"
look "$ARCH";      expect "[PASS] no architecture docs yet (nothing to check)" "fresh project"
look "$ADR";       expect "[PASS] registry and files agree (0 ADR(s))" "fresh project"
look "$LEGACY";    expect "[PASS] $DOCS/overview.md has no legacy local user preference sections" "fresh project"
look "$NUMBERING"; expect "[PASS] numbered architecture sessions match headings and STEP-index seed" "fresh project"
status_is 0 "fresh project"

# --- 2. Architecture docs (check 4) ------------------------------------------------
# Docs written from the template pass. Each doc is judged on its own, so a doc missing fields is
# named with exactly the fields it lacks, and the complete doc beside it is not named.
c="$(fixture arch)"
arch="$c/$DOCS/architecture"
mkdir -p "$arch"
cp "$c/$DOCS/templates/architecture-doc-template.md" "$arch/01-system-overview.md"
cp "$c/$DOCS/templates/architecture-doc-template.md" "$arch/02-phasing-roadmap.md"
doctor "$c"
look "$ARCH"
expect "[PASS] all 2 architecture doc(s) have the required fields" "two docs from the template"
status_is 0 "two docs from the template"

edit "$arch/02-phasing-roadmap.md" '$_ = "" if /^\*\*(Version|Status):\*\*/ || /version log/i' \
  "removing Version, Status and every Version Log mention"
doctor "$c"
look "$ARCH"
expect "[FAIL] $DOCS/architecture/02-phasing-roadmap.md missing: Version Status Version-Log" "a doc with no fields"
refute "01-system-overview.md" "a doc with no fields, beside a complete one"
refute "[PASS]" "a doc with no fields"
status_is 1 "a doc with no fields"

edit "$arch/01-system-overview.md" '$_ = "" if /version log/i' "removing every Version Log mention"
doctor "$c"
look "$ARCH"
expect "[FAIL] $DOCS/architecture/01-system-overview.md missing: Version-Log" "a doc with no Version Log"
expect "[FAIL] $DOCS/architecture/02-phasing-roadmap.md missing:" "a doc with no Version Log, beside one with no fields"

# --- 3. ADR registry against the files (check 5) -------------------------------------
# A row with its file passes. A row with no file and a file with no row each fail, naming the
# number, and each is reported whether or not the other is there.
c="$(fixture adr)"
adr="$c/$DOCS/adr"
printf '| ADR-0001 | A decision | Accepted | 2026-01-15 |\n' >> "$adr/README.md"
printf '# ADR-0001: A decision\n' > "$adr/ADR-0001-a-decision.md"
doctor "$c"
look "$ADR"
expect "[PASS] registry and files agree (1 ADR(s))" "one row with its file"
status_is 0 "one row with its file"

printf '| ADR-0002 | A row with no file | Accepted | 2026-01-16 |\n' >> "$adr/README.md"
doctor "$c"
look "$ADR"
expect "[FAIL] in registry but no file: ADR-0002" "a row with no file"
refute "file on disk but not in registry" "a row with no file"
refute "[PASS]" "a row with no file"
status_is 1 "a row with no file"

printf '# ADR-0003: A file with no row\n' > "$adr/ADR-0003-a-file-with-no-row.md"
doctor "$c"
look "$ADR"
expect "[FAIL] file on disk but not in registry: ADR-0003" "a file with no row"
expect "[FAIL] in registry but no file: ADR-0002" "a file with no row, beside a row with no file"
status_is 1 "a file with no row"

edit "$adr/README.md" '$_ = "" if /^\| ADR-0002 /' "removing the ADR-0002 row"
doctor "$c"
look "$ADR"
expect "[FAIL] file on disk but not in registry: ADR-0003" "only a file with no row"
refute "in registry but no file" "only a file with no row"
status_is 1 "only a file with no row"

# --- 4. Personal preferences in overview.md (check 6) --------------------------------
# Warning only, since the doctor cannot tell whose preferences they are: each section is named
# with its line, and the exit code is left alone.
c="$(fixture legacy)"
printf '\n## Your experience level\n\nSenior.\n\n## Planning communication style\n\nTerse.\n' \
  >> "$c/$DOCS/overview.md"
doctor "$c"
look "$LEGACY"
expect "[WARN] $DOCS/overview.md contains legacy personal preference section(s):" "two legacy sections"
expect ":## Your experience level" "two legacy sections"
expect ":## Planning communication style" "two legacy sections"
refute "[PASS]" "two legacy sections"
status_is 0 "two legacy sections"

# --- 5. Session templates against the seed (check 8) ---------------------------------
# A session added after the Cross-Cutting Review, with no seed row: two findings, one for each.
c="$(fixture extra-session)"
sessions="$c/$DOCS/templates/architecture-sessions"
last="$(cd "$sessions" && ls [0-9][0-9]-*.md | tail -1)"
[ "$last" != "${last%cross-cutting-review.md}" ] || bad "fixture: the last numbered session is $last, not the Cross-Cutting Review"
next=$(( 10#${last%%-*} + 1 ))
printf '# %s — Extra Session (Session 1.%d)\n\nWrite `architecture/%02d-extra.md`.\n' "$SLUG" "$next" "$next" \
  > "$sessions/$(printf '%02d' "$next")-extra.md"
doctor "$c"
look "$NUMBERING"
expect "[FAIL] $DOCS/templates/architecture-sessions/$(printf '%02d' "$next")-extra.md has no matching 1.$next row in $DOCS/templates/step-index-seed.md" \
  "a session with no seed row"
expect "[FAIL] Cross-Cutting Review is not the final numbered session" "a session after the Cross-Cutting Review"
refute "[PASS]" "a session after the Cross-Cutting Review"
status_is 1 "a session after the Cross-Cutting Review"

# A heading whose session number disagrees with its file's prefix.
c="$(fixture heading-number)"
edit "$c/$DOCS/templates/architecture-sessions/02-phasing-roadmap.md" \
  's/\(Session 1\.2\)/(Session 1.3)/ if $. == 1' "renumbering the 1.2 heading"
doctor "$c"
look "$NUMBERING"
expect "[FAIL] $DOCS/templates/architecture-sessions/02-phasing-roadmap.md prefix (2) does not match heading session 1.3" \
  "a heading numbered for another session"
refute "[PASS]" "a heading numbered for another session"
status_is 1 "a heading numbered for another session"

# A seed row whose label no longer matches its session's heading.
c="$(fixture seed-label)"
edit "$c/$DOCS/templates/step-index-seed.md" \
  's/^(\| 1\.2 \| )Phasing & Roadmap( \|)/${1}Phasing and Roadmap$2/' "relabelling the 1.2 seed row"
doctor "$c"
look "$NUMBERING"
expect "[FAIL] $DOCS/templates/architecture-sessions/02-phasing-roadmap.md heading session label ('Phasing & Roadmap') does not match seed row label ('Phasing and Roadmap')" \
  "a seed row relabelled"
refute "[PASS]" "a seed row relabelled"
status_is 1 "a seed row relabelled"

if [ "$failures" -gt 0 ]; then
  printf 'check-docs-and-templates.sh: %d failure(s)\n' "$failures" >&2
  exit 1
fi
echo "check-docs-and-templates.sh: PASS"
