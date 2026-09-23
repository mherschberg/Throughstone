#!/usr/bin/env bash
#
# check.sh — a read-only "doctor" for a Throughstone project. It runs the mechanical
# integrity checks the method otherwise trusts prose (and the agent's memory) to enforce.
# It never modifies files; a FAIL is structural drift that must be fixed, while a WARN is
# missing context or local-workspace state that should be reviewed but does not fail the run.
# Safe to run anytime — intended for the periodic check-in (runbooks/check-in.md) and for CI.
#
# Checks:
#   1. No duplicate STEP numbers in prompts/STEP-index.md — warns when it has no STEP row
#   2. No duplicate ADR numbers in adr/README.md — warns when it holds neither an ADR row nor a
#      registry table
#   3. STEP / substep statuses are from the allowed set — warns on no STEP row, or on a STEP
#      row under no Status column
#   4. Every architecture/NN-*.md carries Version / Status / Version Log
#   5. The ADR registry and the ADR files on disk match (both directions)
#   6. overview.md does not carry legacy local user preferences
#   7. (multi-repo only) No stray files at the workspace root
#   8. Architecture-session template numbers match the STEP-index seed
#   9. Conditional-session templates expose the metadata generic review gates require — none
#      passes; a missing templates/architecture-sessions/ folder warns
#  10. (--check-in only) registries/repos.yml declares its layout, the rows agree with what it
#      declares, and every row can be read and has a location — any repo no recorded remote
#      covers is flagged as a bus-factor risk; warns when the registry declares no layout, when
#      it holds no rows at all, and when it cannot be read
#
# The registry changes on the rare path — a repo created, adopted or split out — so it is not
# validated on every run. Pass --check-in; runbooks/check-in.md is what does.
#
# Usage:  from anywhere — Code/<project>-docs/scripts/check.sh [--check-in]
# Exit:   non-zero if any hard check FAILs; warnings alone do not fail the run.

set -uo pipefail

# --check-in turns on the checks that belong to the periodic check-in rather than to every run.
CHECK_IN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check-in) CHECK_IN=1 ;;
    *) echo "check.sh: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization. Derive all paths from BASH_SOURCE so the
# doctor can be run from any working directory without resolving the template placeholder.
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"
# Printed paths are rendered from the workspace root, because that is where the caller is
# standing: this script never changes the caller directory, and the documented flow runs it
# from the workspace root. links.sh renders its diagnostics the same way.
DOCS_REL="Code/$(basename "$DOCS_DIR")"
# Authoritative project state is split between the workspace-root STEP index and docs-hub
# registries/templates. Keep those assumptions centralized so each check reads the same files.
INDEX="$ROOT/prompts/STEP-index.md"
OVERVIEW="$DOCS_DIR/overview.md"
ADR_INDEX="$DOCS_DIR/adr/README.md"
ARCH_DIR="$DOCS_DIR/architecture"
ADR_DIR="$DOCS_DIR/adr"
SESSION_TEMPLATE_DIR="$DOCS_DIR/templates/architecture-sessions"
STEP_INDEX_SEED="$DOCS_DIR/templates/step-index-seed.md"
REPOS_REGISTRY="$DOCS_DIR/registries/repos.yml"
# The layout the project declares (METHOD.md §7), read once and used by every check that needs
# it. registries/repos.yml states it rather than leaving each reader to work it out from the rows,
# which cannot be done: at bootstrap a mono project has MORE rows than a multi one, and the row
# whose location is "." can never be required of a multi project, so its absence means multi, or a
# project made before the field existed — and nothing can tell those apart. Empty here is that
# absence, and it is not a third layout: nothing here reads a layout out of the workspace, and
# check 10 asks for the declaration instead. (Check 7 does read the workspace, for a different
# question — whether the root is a repository at all — and answers it from the filesystem.) Only a
# key at column 0 is the declaration; rule 2 in that file's own header makes anything indented part
# of a row block, and check 10 fails a declaration written below the rows.
LAYOUT=""
if [ -r "$REPOS_REGISTRY" ]; then
  LAYOUT="$(awk '
    function val(t) { sub(/^[^:]*:[[:space:]]*"?/, "", t); sub(/"?[[:space:]]*$/, "", t); return t }
    /^[[:space:]]*#/ { next }
    /^layout:/ { layout = val($0) }
    END { print layout }
  ' "$REPOS_REGISTRY")"
fi

shopt -s nullglob

fails=0
warns=0
# pass/fail/warn/hdr are presentation helpers only. fail increments the hard-failure count;
# warn increments the advisory count; neither exits early so one run reports all drift.
pass() { printf '  [PASS] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; fails=$((fails + 1)); }
warn() { printf '  [WARN] %s\n' "$1"; warns=$((warns + 1)); }
hdr()  { printf '\n%s\n' "$1"; }
# A suggested remediation under a finding. The doctor diagnoses and prescribes; it never
# edits files — renumbering touches branch/folder names and needs human judgment.
hint() { printf '         → fix: %s\n' "$1"; }

# Emit a newline list as sorted, unique, non-empty lines (for comm).
emit() { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | sort -u; }

echo "Throughstone check — $ROOT"

# --- 1. Duplicate STEP numbers ------------------------------------------------
hdr "1. Duplicate STEP numbers (prompts/STEP-index.md)"
if [ -f "$INDEX" ]; then
  # Invariant: STEP numbers are durable IDs. prompts/STEP-index.md is authoritative, and
  # duplicates catch accidental reuse after planning, branching, or folder creation.
  step_ids="$(grep -oE '^\|[[:space:]]*STEP-[0-9]+' "$INDEX" | grep -oE 'STEP-[0-9]+')"
  step_rows="$(printf '%s\n' "$step_ids" | grep -c .)"
  dups="$(printf '%s\n' "$step_ids" | sort | uniq -d)"
  if [ -n "$dups" ]; then
    fail "duplicate STEP number(s): $(echo "$dups" | tr '\n' ' ')"
    for d in $dups; do
      lns="$(grep -nE "^\|[[:space:]]*$d([[:space:]]|\|)" "$INDEX" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')"
      printf '         %s appears on line(s): %s\n' "$d" "$lns"
    done
    maxn="$(grep -oE '^\|[[:space:]]*STEP-[0-9]+' "$INDEX" | grep -oE '[0-9]+' | sort -n | tail -1)"
    hint "renumber the duplicate (the one reserved later) to STEP-$((maxn + 1)) — never reuse or delete a number; mark a row Abandoned if it won't be built. See $DOCS_REL/runbooks/collaboration.md §2."
  elif [ "$step_rows" -eq 0 ]; then
    # init.sh reserves STEP-1 and a STEP number is never deleted, so an index with no STEP row
    # has lost its table. A pass here would vouch for rows nobody read.
    warn "found no STEP rows in prompts/STEP-index.md — nothing to check"
    hint "a STEP row starts at the left margin with its number, as in | STEP-1 |. Restore the table from git history; a number is never deleted, only marked Abandoned."
  else
    pass "no duplicate STEP numbers ($step_rows STEP row(s))"
  fi
elif [ "$LAYOUT" = "multi" ]; then
  # Why the file can be absent with nothing wrong, and it is true in one layout only: in multi-repo
  # the roadmap is its own repository, so a checkout of the docs hub alone never carries it — which
  # is how the generated project's own CI runs. In mono-repo-for-now prompts/ is a folder inside the
  # one repository, so the explanation would be false, and a project that declares no layout is not
  # one to guess about.
  warn "no prompts/STEP-index.md at the workspace root — skipping the STEP checks; in a multi-repo project the roadmap is the prompts/ repo, so a checkout holding the docs hub alone never carries it"
else
  warn "no prompts/STEP-index.md at the workspace root — skipping the STEP checks"
fi

# --- 2. Duplicate ADR numbers -------------------------------------------------
hdr "2. Duplicate ADR numbers ($DOCS_REL/adr/README.md)"
if [ -f "$ADR_INDEX" ]; then
  # Invariant: ADR numbers are durable decision IDs. adr/README.md is the registry authority,
  # and duplicates catch copy/paste rows or renumbering drift before files are reconciled.
  adr_ids="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE 'ADR-[0-9]+')"
  adr_rows="$(printf '%s\n' "$adr_ids" | grep -c .)"
  dups="$(printf '%s\n' "$adr_ids" | sort | uniq -d)"
  if [ -n "$dups" ]; then
    fail "duplicate ADR number(s): $(echo "$dups" | tr '\n' ' ')"
    for d in $dups; do
      lns="$(grep -nE "^\|[[:space:]]*$d([[:space:]]|\|)" "$ADR_INDEX" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')"
      printf '         %s appears on line(s): %s\n' "$d" "$lns"
    done
    maxn="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE '[0-9]+' | sed 's/^0*//' | sort -n | tail -1)"
    hint "renumber the later duplicate to $(printf 'ADR-%04d' "$((maxn + 1))") and rename its file to match — never reuse a number. See $DOCS_REL/adr/README.md and $DOCS_REL/runbooks/collaboration.md §6."
  elif [ "$adr_rows" -eq 0 ] && ! grep -qE '^\|[[:space:]]*ADR[[:space:]]*\|' "$ADR_INDEX"; then
    # No ADR row is how every project starts, so the count alone cannot tell a new registry
    # from an emptied one. The table header can: it ships with the file and stays when empty.
    warn "found no ADR rows and no registry table in $DOCS_REL/adr/README.md — nothing to check"
    hint "the registry table stays even with no ADRs in it: restore its header row, | ADR | Title | Status | Date |, from git history."
  else
    pass "no duplicate ADR numbers ($adr_rows ADR row(s))"
  fi
else
  warn "no $DOCS_REL/adr/README.md — skipping ADR-number check"
fi

# --- 3. Valid STEP / substep statuses -----------------------------------------
hdr "3. Statuses valid (Planned · In progress · Done · Deferred · Abandoned · N/A)"
if [ -f "$INDEX" ]; then
  # Invariant: resolver-visible status cells use the METHOD.md vocabulary exactly.
  # prompts/STEP-index.md is authoritative; invalid values break status.sh and agent handoffs.
  #
  # Find each table's Status column from its header row, then validate that cell in data rows.
  # The parser depends on Markdown table headers, not fixed column positions; STEP rows may not
  # use N/A because only substeps can be structurally inapplicable.
  #
  # A STEP row under a header with no Status column is never validated, so STEP rows are also
  # counted by their own shape — the one the duplicate-number check reads — and one that no
  # Status column covers is a warning, not a pass.
  scan="$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      if ($0 !~ /^[[:space:]]*\|/) { inrow = 0; statuscol = 0; next }   # left a table
      steprow = ($0 ~ /^\|[[:space:]]*STEP-[0-9]+/)
      steprows += steprow
      ishdr = 0; isstep = 0; issub = 0
      for (i = 1; i <= NF; i++) {
        c = trim($i)
        if (c == "Status") { ishdr = 1; statuscol = i }
        if (c == "STEP") isstep = 1
        if (c == "Substep") issub = 1
      }
      if (ishdr && isstep) tablekind = "STEP"
      if (ishdr && issub)  tablekind = "SUB"
      if (ishdr) { inrow = 1; subtable = issub; next }
      if (!inrow || statuscol == 0) next
      stepread += steprow
      sc = trim($statuscol)
      # The separator row is the one whose first cell is dashes too. A data row whose Status is
      # dashes or blank is checked like any other value, and fails.
      if (sc ~ /^:?-+:?$/ && trim($2) ~ /^:?-+:?$/) next
      subread += subtable
      if (sc != "Planned" && sc != "In progress" && sc != "Done" && sc != "Deferred" && sc != "Abandoned" && sc != "N/A")
        print trim($2) " -> \"" sc "\""
      else if (sc == "N/A" && tablekind != "SUB")
        print trim($2) " -> \"N/A\" (only substeps may use N/A)"
    }
    END { print "count\t" (stepread + 0) "\t" (steprows + 0) "\t" (subread + 0) }
  ' "$INDEX")"
  step_read="$(printf '%s\n' "$scan" | awk -F'\t' '$1 == "count" { print $2 }')"
  step_seen="$(printf '%s\n' "$scan" | awk -F'\t' '$1 == "count" { print $3 }')"
  sub_read="$(printf '%s\n' "$scan"  | awk -F'\t' '$1 == "count" { print $4 }')"
  bad="$(printf '%s\n' "$scan" | awk -F'\t' '$1 != "count"')"
  if [ -n "$bad" ]; then
    fail "invalid status value(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$bad"
    hint "use exactly one of: Planned · In progress · Done · Deferred · Abandoned (a substep may also be N/A). See $DOCS_REL/METHOD.md §1."
  fi
  if [ "${step_seen:-0}" -eq 0 ]; then
    warn "found no STEP rows in prompts/STEP-index.md — no STEP status checked"
  elif [ "${step_read:-0}" -lt "$step_seen" ]; then
    warn "read the status of ${step_read:-0} of $step_seen STEP row(s) — a status is read only under a header row with a Status column"
    hint "give every STEP table the header row in $DOCS_REL/templates/step-index-seed.md; a STEP row under a renamed or missing header is not checked."
  elif [ -z "$bad" ]; then
    pass "all statuses valid ($step_read STEP row(s), $sub_read substep row(s))"
  fi
else
  warn "no prompts/STEP-index.md at the workspace root — skipping the status check"
fi

# --- 4. Architecture-doc frontmatter ------------------------------------------
hdr "4. Architecture docs carry Version / Status / Version Log"
# Invariant: each numbered architecture document exposes reviewable lifecycle metadata.
# templates/architecture-doc-template.md defines the shape; this catches hand-written docs that skipped
# the template or lost the Version Log during edits.
docs=("$ARCH_DIR"/[0-9][0-9]-*.md)
if [ ${#docs[@]} -eq 0 ]; then
  pass "no architecture docs yet (nothing to check)"
else
  missing_any=0
  for f in "${docs[@]}"; do
    b="$(basename "$f")"
    missing=""
    grep -qF '**Version:**'  "$f" || missing="$missing Version"
    grep -qF '**Status:**'   "$f" || missing="$missing Status"
    grep -qiF 'version log'  "$f" || missing="$missing Version-Log"
    if [ -n "$missing" ]; then fail "$b missing:$missing"; missing_any=1; fi
  done
  if [ "$missing_any" -eq 0 ]; then
    pass "all ${#docs[@]} architecture doc(s) have the required fields"
  else
    hint "add the missing field(s) from $DOCS_REL/templates/architecture-doc-template.md (Version / Status header, and a Version Log table). See $DOCS_REL/METHOD.md §6."
  fi
fi

# --- 5. ADR registry <-> files on disk ----------------------------------------
hdr "5. ADR registry matches ADR files on disk (both directions)"
if [ -f "$ADR_INDEX" ]; then
  # Invariant: each registered ADR has exactly one file, and each ADR file is registered.
  # The registry is adr/README.md; the disk authority for materialized decisions is adr/ADR-*.md.
  # Compare normalized ID sets both ways to catch stale rows and orphan files.
  reg_ids="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE 'ADR-[0-9]+')"
  disk_ids=""
  for f in "$ADR_DIR"/ADR-*.md; do disk_ids="$disk_ids$(basename "$f" | grep -oE 'ADR-[0-9]+')"$'\n'; done
  # comm requires sorted inputs; emit normalizes blank/duplicate IDs before the set difference.
  missing_files="$(comm -23 <(emit "$reg_ids") <(emit "$disk_ids"))"   # in registry, no file
  missing_rows="$(comm -13 <(emit "$reg_ids") <(emit "$disk_ids"))"    # file, not in registry
  ok=1
  [ -n "$missing_files" ] && { fail "in registry but no file: $(echo "$missing_files" | tr '\n' ' ')"; ok=0; hint "create the ADR file(s) from $DOCS_REL/templates/adr-template.md, or remove the stale registry row(s) in $DOCS_REL/adr/README.md."; }
  [ -n "$missing_rows" ]  && { fail "file on disk but not in registry: $(echo "$missing_rows" | tr '\n' ' ')"; ok=0; hint "add a registry row in $DOCS_REL/adr/README.md for the file(s), or delete the file if it shouldn't exist."; }
  [ "$ok" -eq 1 ] && pass "registry and files agree ($(emit "$reg_ids" | grep -c . ) ADR(s))"
else
  warn "no $DOCS_REL/adr/README.md — skipping ADR registry/disk check"
fi

# --- 6. Legacy local user profile fields --------------------------------------
hdr "6. Legacy local user profile fields"
# In older projects, the first user's communication preferences were stored in overview.md.
# They now belong in root .throughstone/local-user.md, because each contributor has their own
# local profile. This is warning-only: doctor cannot know which human the old values represent.
if [ -f "$OVERVIEW" ]; then
  legacy_profile_fields="$(grep -nE '^## (Your experience level|Planning communication style)[[:space:]]*$' "$OVERVIEW" || true)"
  if [ -n "$legacy_profile_fields" ]; then
    warn "$DOCS_REL/overview.md contains legacy personal preference section(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$legacy_profile_fields"
    hint "create/update root .throughstone/local-user.md for the active user, then remove these personal-preference sections from $DOCS_REL/overview.md after confirming they are not project facts. See $DOCS_REL/UPDATING-THROUGHSTONE.md."
  else
    pass "$DOCS_REL/overview.md has no legacy local user preference sections"
  fi
else
  pass "no $DOCS_REL/overview.md in the docs hub — nothing to read, so skipping the legacy local user profile check"
fi

# --- 7. Workspace-root hygiene (multi-repo only) ------------------------------
hdr "7. Workspace-root hygiene (multi-repo only)"
# Invariant: in generated multi-repo workspaces, the root is a per-machine shell and durable
# content should live inside repos. CI usually checks out only one repo, and this scaffold can
# be a mono-repo/template checkout, so those contexts intentionally relax the local hygiene rule.
if [ -n "${CI:-}" ]; then
  pass "CI environment — root hygiene is a local-workspace check (a single repo is checked out here); skipping"
elif [ -e "$ROOT/.git" ]; then
  pass "workspace root is itself a repo (mono-repo or the template) — hygiene rule relaxed; skipping"
else
  # Allowed root entries are per-machine pointers, repo containers, and transient prompt intake.
  # One list element per entry: `Upcoming Prompts` holds a space, and a list joined on spaces
  # cannot tell that entry from two entries called `Upcoming` and `Prompts`.
  allow=(CLAUDE.md AGENTS.md init.sh doctor.sh .git .gitignore .gitattributes .DS_Store .claude .throughstone Code prompts "Upcoming Prompts")
  # A registered repo may sit at any path inside the workspace and is never made to move
  # (METHOD.md §7), so the root entry a row's location: points into is expected here too — the
  # project put it there deliberately and the registry is where it said so. Only the head of the
  # path is read; whether the rows themselves are well formed is check 10's question.
  registry_note="and $DOCS_REL/registries/repos.yml could not be read, so a repo registered at one is named here too"
  if [ -r "$REPOS_REGISTRY" ]; then
    registry_note="and no row in $DOCS_REL/registries/repos.yml registers a path starting at one"
    while IFS= read -r registered; do
      allow+=("$registered")
    done < <(awk '
      function val(t) { sub(/^[^:]*:[[:space:]]*"?/, "", t); sub(/"?[[:space:]]*$/, "", t); return t }
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*location:/ {
        loc = val($0)
        sub(/^\.\//, "", loc)   # ./name and name are one path; the split below reads the second
        sub(/\/.*$/, "", loc)
        # "." is the workspace root itself rather than an entry in it, and a location beginning
        # at "/" leaves no root entry to name.
        if (loc != "" && loc != ".") print loc
      }
    ' "$REPOS_REGISTRY")
  fi
  stray=""
  for entry in "$ROOT"/* "$ROOT"/.[!.]*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    known=0
    for allowed in "${allow[@]}"; do
      [ "$name" = "$allowed" ] && { known=1; break; }
    done
    [ "$known" -eq 1 ] || stray="$stray $name"
  done
  if [ -n "$stray" ]; then
    warn "unexpected entr(ies) at workspace root:$stray — should these be inside a repo (usually the docs hub)?"
    hint "none of these is a pointer this method writes, $registry_note. Register the repo if that is what it is — a repo may sit at any path inside the workspace and never has to move — and otherwise move it into a repo, almost always $DOCS_REL/. See $DOCS_REL/METHOD.md §7."
  else
    pass "only the expected pointers / repos at the workspace root"
  fi
fi

# --- 8. Architecture-session template numbering ------------------------------
hdr "8. Architecture-session template numbering"
# Invariant: numbered STEP-1 session templates, their headings, and the STEP-index seed remain
# in lockstep. The seed is the generated project's initial roadmap; template drift here becomes
# broken kickoff sequencing after init.
session_templates=("$SESSION_TEMPLATE_DIR"/[0-9][0-9]-*.md)
if [ ${#session_templates[@]} -eq 0 ]; then
  warn "no numbered architecture-session templates found — skipping numbering check"
elif [ ! -f "$STEP_INDEX_SEED" ]; then
  warn "no $DOCS_REL/templates/step-index-seed.md found — skipping numbering check"
else
  numbering_ok=1
  max_prefix=0
  max_file=""
  template_minors=""
  for f in "${session_templates[@]}"; do
    b="$(basename "$f")"
    prefix="${b%%-*}"
    prefix_n=$((10#$prefix))
    [ "$prefix_n" -gt "$max_prefix" ] && { max_prefix=$prefix_n; max_file="$b"; }

    # Each numbered session declares its STEP-1 minor in the H1. The filename prefix, heading
    # session number, seed-row label, and expected output path must all describe the same slot.
    heading="$(grep -m1 -E '^# .*Session 1\.[0-9]+\)' "$f" || true)"
    if [ -z "$heading" ]; then
      fail "$b has no heading with '(Session 1.N)'"
      numbering_ok=0
      continue
    fi
    minor="$(printf '%s\n' "$heading" | sed -E 's/.*Session 1\.([0-9]+).*/\1/')"
    template_minors="$template_minors $minor "
    if [ "$prefix_n" -ne "$minor" ]; then
      fail "$b prefix ($prefix_n) does not match heading session 1.$minor"
      numbering_ok=0
    fi

    # The seed row provides the generated roadmap label and output contract for this session.
    # Parsing by columns keeps the check tied to the table shape instead of incidental spacing.
    title="$(printf '%s\n' "$heading" | sed -E 's/^# //; s/^.* — //; s/^.* - //; s/[[:space:]]+\(Session 1\.[0-9]+\).*//')"
    seed_row="$(awk -F'|' -v n="$minor" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^[[:space:]]*\|/ {
        substep = trim($2)
        if (substep == "1." n) { print trim($3) "|" trim($5); exit }
      }
    ' "$STEP_INDEX_SEED")"
    if [ -z "$seed_row" ]; then
      fail "$b has no matching 1.$minor row in $DOCS_REL/templates/step-index-seed.md"
      numbering_ok=0
      seed_label=""
      seed_output=""
    else
      seed_label="${seed_row%%|*}"
      seed_output="${seed_row#*|}"
      title_norm="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')"
      seed_label_norm="$(printf '%s' "$seed_label" | tr '[:upper:]' '[:lower:]')"
      if [ "$title_norm" != "$seed_label_norm" ]; then
        fail "$b heading session label ('$title') does not match seed row label ('$seed_label')"
        numbering_ok=0
      fi
    fi

    # Architecture sessions write architecture/NN-*.md docs. The Cross-Cutting Review is the
    # exception: it produces a review doc after all numbered architecture docs exist.
    if [[ "$b" != *cross-cutting-review.md ]]; then
      if ! grep -Eq "^Write \`architecture/${prefix}-[^\`]+\`" "$f"; then
        fail "$b has no line starting with Write \`architecture/${prefix}-…\`"
        numbering_ok=0
      fi
      if [ -n "$seed_output" ] && ! printf '%s' "$seed_output" | grep -q "architecture/${prefix}-"; then
        fail "$b seed row output ('$seed_output') does not point at architecture/${prefix}-…"
        numbering_ok=0
      fi
    elif [ -n "$seed_output" ] && [ "$seed_output" != "review doc" ]; then
      fail "$b seed row output ('$seed_output') should be 'review doc'"
      numbering_ok=0
    fi
  done

  # Check the reverse direction: every numbered STEP-1 seed row must have a matching template,
  # or generated projects will contain a roadmap session agents cannot run by file.
  extra_seed_rows="$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^[[:space:]]*\|/ {
      substep = trim($2)
      if (substep ~ /^1\.[0-9]+$/) {
        n = substep
        sub(/^1\./, "", n)
        print n "|" trim($3)
      }
    }
  ' "$STEP_INDEX_SEED")"
  while IFS='|' read -r seed_minor seed_label; do
    [ -z "${seed_minor:-}" ] && continue
    case "$template_minors" in
      *" $seed_minor "*) : ;;
      *)
        fail "$DOCS_REL/templates/step-index-seed.md has 1.$seed_minor ('$seed_label') but no matching numbered session template"
        numbering_ok=0
        ;;
    esac
  done <<< "$extra_seed_rows"

  # The Cross-Cutting Review must stay last because it checks consistency across the complete
  # architecture set; adding numbered architecture sessions after it would make the review stale.
  if [[ "$max_file" != *cross-cutting-review.md ]]; then
    fail "Cross-Cutting Review is not the final numbered session (last is $max_file)"
    numbering_ok=0
  fi

  if [ "$numbering_ok" -eq 1 ]; then
    pass "numbered architecture sessions match headings and STEP-index seed; Cross-Cutting Review is last"
  else
    hint "keep numbered session files, their '(Session 1.N)' headings, and $DOCS_REL/templates/step-index-seed.md rows in lockstep; the Cross-Cutting Review remains the final numbered session."
  fi
fi

# --- 9. Conditional-session template contract --------------------------------
hdr "9. Conditional-session template contract"
# Invariant: conditional sessions are optional architecture gates, but generic review/resume
# tooling still needs a common metadata contract: applicability, invocation, outputs, next
# action, active PLAN handling, architecture index updates, and substep completion language.
conditional_templates=("$SESSION_TEMPLATE_DIR"/conditional-*.md)
# Conditional templates are optional and a project may delete them, so having none passes. The
# folder they live in is not optional — it holds the numbered sessions too — so its absence warns.
if [ ! -d "$SESSION_TEMPLATE_DIR" ]; then
  warn "no $DOCS_REL/templates/architecture-sessions/ folder — skipping conditional-session check"
elif [ ${#conditional_templates[@]} -eq 0 ]; then
  pass "no conditional-session templates found (nothing to check)"
else
  conditional_ok=1
  for f in "${conditional_templates[@]}"; do
    b="$(basename "$f")"
    missing=""
    # Presence checks are intentionally textual: the contract is for generic agents and review
    # gates that need stable cues without knowing each conditional session's domain.
    grep -qE '^# .*Conditional Session' "$f" || missing="$missing heading"
    grep -qF '> **Conditional.**' "$f" || missing="$missing applicability"
    grep -qi 'Run it by name' "$f" || missing="$missing invocation"
    grep -qE '^## Output[[:space:]]*$' "$f" || missing="$missing Output"
    grep -qE '^## Next[[:space:]]*$' "$f" || missing="$missing Next"
    grep -qi 'follow-up STEP' "$f" || missing="$missing late-follow-up-mode"
    grep -qiE 'active (STEP |follow-up )?PLAN' "$f" || missing="$missing active-PLAN-read"
    grep -qF 'architecture/README.md' "$f" || missing="$missing architecture-index-update"
    grep -qiE 'mark (this|the active) substep done' "$f" || missing="$missing active-substep-update"
    if [ -n "$missing" ]; then
      fail "$b missing:$missing"
      conditional_ok=0
    fi
  done
  if [ "$conditional_ok" -eq 1 ]; then
    pass "all ${#conditional_templates[@]} conditional template(s) expose applicability, invocation, output, next action, and complete late-follow-up bookkeeping"
  else
    hint "copy an existing conditional template's contract: explicit applicability, 'Run it by name', Output, Next, and both STEP-1 / late-follow-up PLAN, architecture-index, and active-substep bookkeeping. See $DOCS_REL/METHOD.md §4."
  fi
fi

# --- 10. Repo registry (registries/repos.yml) — check-in only ------------------
# Deliberately minimal, and deliberately not run on every invocation. The registry changes when
# a repo is created, adopted or split out; the doctor runs constantly during STEPS. Validating
# the rare path on the common one is what this check used to do, at 285 lines.
#
# What is left is the part a machine is genuinely better at than a person: noticing that a repo
# has no remote, so the work lives on exactly one laptop. A malformed row is fixed by whoever
# just edited it — see runbooks/register-repo.md, which raises anything that did not work.
#
# A row is covered by its own remote:, or — in the mono-repo-for-now layout — by the root
# repository's remote, because there every other row's path sits inside that one repository's
# working tree. Which of the two rules applies comes from the `layout:` the registry declares, not
# from the rows: a reader cannot work the layout out from them, and the row with `location: "."` is
# the root repository's entry here rather than a signal about the project. The root row is covered
# by nothing else: if it has no remote, it is flagged like any other repo. A registry that declares
# no layout is not judged either way — it is asked to declare one.
#
# The declaration and the rows can disagree, and the second half of this check is what says so,
# because one fact recorded in two places drifts. A mono project's rows are folders inside its one
# repository, so a row of its own with a remote of its own is a separate repository — which a
# mono-repo-for-now project cannot hold. It converts to multi-repo first
# (`runbooks/splitting-repos.md` Case 2), and that is what the finding says.
if [ "$CHECK_IN" -eq 1 ]; then
  hdr "10. Repo registry ($DOCS_REL/registries/repos.yml)"
  if [ ! -f "$REPOS_REGISTRY" ]; then
    warn "no $DOCS_REL/registries/repos.yml — skipping repo registry check"
  elif [ ! -r "$REPOS_REGISTRY" ]; then
    # -f is type and existence, not readability. Without this the walk reads nothing out of a
    # registry that is entirely intact, and the zero-row warning below would tell whoever is
    # holding it to go and restore rows that never left.
    warn "cannot read $DOCS_REL/registries/repos.yml — skipping repo registry check"
  else
    # Walk each `- name:` block and report the rows missing a location, and the rows no
    # recorded remote covers. Comment lines are skipped, so the example row at the bottom is not
    # counted. A row is found by its `- name:` line, so a row written any other way is not read,
    # and its fields land on the row above it. Every list entry is therefore counted apart from
    # the walk, under the same comment rule, and a registry whose two counts disagree fails: the
    # other findings may then name the wrong repo, and nothing can say where the unread one lives.
    reg_flat="$(awk -v layout="$LAYOUT" '
      function val(t) { sub(/^[^:]*:[[:space:]]*"?/, "", t); sub(/"?[[:space:]]*$/, "", t); return t }
      # `.` and `./` are one path, the workspace root, and check 7 in this file already reads them
      # as one. Comparing the spelling instead would put a root row spelled `./` outside every rule
      # below: reported as a repository of its own under mono, and missed under multi.
      function isroot(l) { sub(/\/+$/, "", l); return (l == ".") }
      function stash() {
        if (!have) return
        n++; names[n] = name; locs[n] = loc; rems[n] = rem
        if (isroot(loc)) root = 1
        have = 0
      }
      /^[[:space:]]*#/ { next }
      # How many declarations there are, and whether one sits below the rows. Both are the shape
      # that file states for itself, not a preference of this check: one key, at column 0, above
      # `repos:`.
      /^layout:/ { layouts++; if (seen_repos) below = 1 }
      /^repos:/  { seen_repos = 1 }
      /^[[:space:]]*-[[:space:]]/ || /^[[:space:]]*-$/ { entries++ }
      /^[[:space:]]*-[[:space:]]*name:/ { stash(); name = val($0); loc = ""; rem = ""; have = 1; next }
      /^[[:space:]]*location:/ { loc = val($0) }
      /^[[:space:]]*remote:/   { rem = val($0) }
      END {
        stash()
        print "count\t" (n + 0) "\t" (entries + 0)
        print "root\t" (root + 0)
        print "layout\t" (layouts + 0) "\t" (below + 0)
        for (i = 1; i <= n; i++) {
          if (locs[i] == "") print "location\t" names[i]
          # A row that is not the workspace root and carries a remote of its own describes a
          # repository rather than a folder. Harmless in multi, where that is every row; read
          # below only under a mono declaration, which forbids it. A row with no location at all
          # is not a second repository; it is the failure of the row above, reported there.
          if (locs[i] != "" && !isroot(locs[i]) && rems[i] != "") print "own-remote\t" names[i] "\t" locs[i]
          # Covered by its own remote, or — under a mono declaration — by the remote of the row
          # at "." that contains it. The location travels with the name: the fix acts on that
          # repo, and a name alone does not say where it is. An undeclared layout answers
          # neither way, so nothing is judged.
          if (layout != "mono" && layout != "multi") continue
          # Under multi the root row is condemned by the reconciliation below, which says to delete
          # it. Naming it here as well would tell the reader to give that same row a remote.
          if (layout == "multi" && isroot(locs[i])) continue
          if (rems[i] == "" && !(layout == "mono" && !isroot(locs[i]))) print "remote\t" names[i] "\t" locs[i]
        }
      }
    ' "$REPOS_REGISTRY")"

    rows="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "count" { print $2 }')"
    entries="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "count" { print $3 }')"
    root="$(printf '%s\n' "$reg_flat"    | awk -F'\t' '$1 == "root"  { print $2 }')"
    layouts="$(printf '%s\n' "$reg_flat"  | awk -F'\t' '$1 == "layout" { print $2 }')"
    below="$(printf '%s\n' "$reg_flat"    | awk -F'\t' '$1 == "layout" { print $3 }')"
    no_loc="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "location" { print $2 }')"
    own_rem="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "own-remote" { print $2 " (" $3 ")" }')"
    no_rem="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "remote"   { print $2 " (" $3 ")" }')"

    if [ "$rows" != "$entries" ]; then
      fail "read $rows of $entries row(s) — a row is read only from its - name: line"
      hint "start every row with its - name: line, then run the check again; until the two numbers match, the other findings here may name the wrong repo."
    fi
    if [ -n "$no_loc" ]; then
      fail "row(s) with no location: $(printf '%s' "$no_loc" | tr '\n' ' ')"
      hint "give every row a location: — the workspace-relative path the repo lives at; without one, nothing can find the repo."
    fi

    # What the registry declares, and whether its rows agree with it. The two are one fact written
    # in two shapes, and a fact kept in two places drifts — so a disagreement is reported here
    # rather than settled by quietly preferring one of them. Each finding speaks on its own, like
    # every other one in this file: nothing exits early, so one run reports all the drift there is,
    # and `recon` only says whether the pass line below may be printed.
    #
    # First the declaration itself, which is read from the file rather than from the rows and so is
    # answerable whatever state they are in.
    recon=1
    if [ "${layouts:-0}" -eq 0 ]; then
      recon=0
      warn "$DOCS_REL/registries/repos.yml does not declare a layout, so its rows cannot be read as folders or as repos"
      hint "add one line at the left margin above repos: — layout: mono if the workspace root is the one repository this project has, layout: multi if each row is a repository of its own (METHOD.md §7). A project bootstrapped before the field existed has none; see $DOCS_REL/UPDATING-THROUGHSTONE.md. Until it is there, the remote coverage below is not judged."
    elif [ "${layouts:-0}" -gt 1 ]; then
      # Last one wins in every reader, so two lines make the layout whatever the bottom one says —
      # including when someone adds the line this check asked for above a stale one and it is
      # overruled from below.
      recon=0
      fail "$DOCS_REL/registries/repos.yml declares a layout $layouts times, so which one the project is in depends on which line a reader stops at"
      hint "keep one layout: line, at the left margin above repos:, and delete the others."
    elif [ -z "$LAYOUT" ]; then
      recon=0
      fail "$DOCS_REL/registries/repos.yml has a layout: line with nothing after it"
      hint "write mono or multi after the colon — an empty value says no more than no line at all, and it takes precedence over one added above it. See METHOD.md §7."
    elif [ "$LAYOUT" != "mono" ] && [ "$LAYOUT" != "multi" ]; then
      recon=0
      fail "$DOCS_REL/registries/repos.yml declares layout: $LAYOUT, which is not a layout"
      hint "the two values are mono and multi, and nothing else is read as either, so the remote coverage below is not judged. See METHOD.md §7."
    fi
    if [ "${below:-0}" -eq 1 ]; then
      recon=0
      fail "$DOCS_REL/registries/repos.yml declares its layout below the rows, where the last row owns it"
      hint "move the layout: line above repos:. Anything that rewrites a row scans forward from its - name: to the next one and nothing stops that scan at the end of the list, so a key under the rows sits inside the last row block and is rewritten as one of its fields."
    fi
    # Then the rows, and only when the walk above read all of them and there were some to read.
    # These compare the declaration against what the rows say, so on a registry the walk could not
    # read they would report a row as absent that is there, or as a repository on the strength of a
    # remote: that leaked onto it from the row below — and send the reader to a repository split for
    # a field in the wrong place. The count failure above is the finding that state needs.
    if [ "$rows" = "$entries" ] && [ "${rows:-0}" -gt 0 ]; then
      if [ "$LAYOUT" = "mono" ] && [ "${root:-0}" -eq 0 ]; then
        recon=0
        fail "declares layout: mono and has no row for the workspace root — the one repository a mono project has is missing from its own inventory"
        hint "add a row whose location: is \".\", carrying the root repository's remote: if it has one — the recipe is in $DOCS_REL/UPDATING-THROUGHSTONE.md. Nothing else here can say whether that repository is backed up, so until it is there the rows below it are not judged."
      fi
      if [ "$LAYOUT" = "multi" ] && [ "${root:-0}" -eq 1 ]; then
        recon=0
        fail "declares layout: multi and carries a row whose location: is \".\" — the workspace root is not a repository in that layout"
        hint "delete the workspace-root row, or correct the declaration to layout: mono if the root really is this project's one repository. In multi-repo the root is a per-machine shell, not a repo (METHOD.md §7)."
      fi
      if [ "$LAYOUT" = "mono" ] && [ -n "$own_rem" ]; then
        recon=0
        fail "declares layout: mono and registers a separate repository: $(printf '%s' "$own_rem" | tr '\n' ' ')"
        hint "a mono-repo-for-now project is one repository, so every other row is a folder inside it and carries no remote of its own. Convert to multi-repo first — $DOCS_REL/runbooks/splitting-repos.md Case 2, which is what flips this file's layout: to multi — and register the repo after that. If the conversion has already happened, the declaration is what is stale."
      fi
    fi

    if [ -n "$no_rem" ]; then
      warn "repo(s) with no remote: $(printf '%s' "$no_rem" | tr '\n' ' ')"
      hint "a repo with no remote lives on one machine — a bus factor of one. Record the URL in remote: if it already has one; if not, create one — private, widening is a separate decision — or accept the risk deliberately."
    fi
    # Zero rows is not a project with no repos. This file lives in the docs hub, which has a row
    # of its own, and init.sh writes that row and prompts/ before anyone can run the doctor; no
    # procedure that edits the registry takes a row away without putting repos in its place. So
    # no rows means the rows are gone, and a pass here would vouch for the whole inventory on the
    # strength of having read none of it. Both counts, because a registry with entries the walk
    # could not read already fails above, and it is that failure the reader needs, not this one.
    if [ "${rows:-0}" -eq 0 ] && [ "${entries:-0}" -eq 0 ]; then
      warn "found no repo rows in $DOCS_REL/registries/repos.yml — nothing to check"
      hint "every project has a row for the docs hub and one for prompts/, and init.sh writes both: a registry with neither has lost them. Restore the rows from git history — $DOCS_REL/runbooks/register-repo.md is what writes a row for a repo that never had one."
    elif [ "$rows" = "$entries" ] && [ -z "$no_loc" ] && [ -z "$no_rem" ] && [ "$recon" -eq 1 ]; then
      # The layout is named because it is what decided the coverage verdict: under mono the root
      # row's remote covers the folder rows, under multi every row answers for itself.
      pass "$rows row(s) in a $LAYOUT project: all have a location, and a recorded remote covers every one"
    fi
  fi
else
  hdr "10. Repo registry ($DOCS_REL/registries/repos.yml)"
  pass "skipped — run with --check-in (this check belongs to the periodic check-in)"
fi

# --- Summary ------------------------------------------------------------------
hdr "Summary"
printf '  %d fail(s), %d warning(s)\n' "$fails" "$warns"
if [ "$fails" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
fi
echo "  RESULT: OK"
exit 0
