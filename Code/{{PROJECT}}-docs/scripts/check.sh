#!/usr/bin/env bash
#
# check.sh — a read-only "doctor" for a Throughstone project. It runs the mechanical
# integrity checks the method otherwise trusts prose (and the agent's memory) to enforce.
# It never modifies files; a FAIL is structural drift that must be fixed, while a WARN is
# missing context or local-workspace state that should be reviewed but does not fail the run.
# Safe to run anytime — intended for the periodic check-in (runbooks/check-in.md) and for CI.
#
# Checks:
#   1. No duplicate STEP numbers in prompts/STEP-index.md
#   2. No duplicate ADR numbers in adr/README.md
#   3. STEP / substep statuses are from the allowed set
#   4. Every architecture/NN-*.md carries Version / Status / Version Log
#   5. The ADR registry and the ADR files on disk match (both directions)
#   6. overview.md does not carry legacy local user preferences
#   7. (multi-repo only) No stray files at the workspace root
#   8. Architecture-session template numbers match the STEP-index seed
#   9. Conditional-session templates expose the metadata generic review gates require
#  10. overview.md's optional CHECK-IN-CADENCE marker, if present, is a positive integer
#  11. (--check-in only) Every registries/repos.yml row has a location, and any repo no
#      recorded remote covers is flagged as a bus-factor risk
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
  dups="$(grep -oE '^\|[[:space:]]*STEP-[0-9]+' "$INDEX" | grep -oE 'STEP-[0-9]+' | sort | uniq -d)"
  if [ -n "$dups" ]; then
    fail "duplicate STEP number(s): $(echo "$dups" | tr '\n' ' ')"
    for d in $dups; do
      lns="$(grep -nE "^\|[[:space:]]*$d([[:space:]]|\|)" "$INDEX" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')"
      printf '         %s appears on line(s): %s\n' "$d" "$lns"
    done
    maxn="$(grep -oE '^\|[[:space:]]*STEP-[0-9]+' "$INDEX" | grep -oE '[0-9]+' | sort -n | tail -1)"
    hint "renumber the duplicate (the one reserved later) to STEP-$((maxn + 1)) — never reuse or delete a number; mark a row Abandoned if it won't be built. See $DOCS_REL/runbooks/collaboration.md §2."
  else
    pass "no duplicate STEP numbers"
  fi
else
  warn "no prompts/STEP-index.md yet (project not initialized?) — skipping STEP checks"
fi

# --- 2. Duplicate ADR numbers -------------------------------------------------
hdr "2. Duplicate ADR numbers ($DOCS_REL/adr/README.md)"
if [ -f "$ADR_INDEX" ]; then
  # Invariant: ADR numbers are durable decision IDs. adr/README.md is the registry authority,
  # and duplicates catch copy/paste rows or renumbering drift before files are reconciled.
  dups="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE 'ADR-[0-9]+' | sort | uniq -d)"
  if [ -n "$dups" ]; then
    fail "duplicate ADR number(s): $(echo "$dups" | tr '\n' ' ')"
    for d in $dups; do
      lns="$(grep -nE "^\|[[:space:]]*$d([[:space:]]|\|)" "$ADR_INDEX" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')"
      printf '         %s appears on line(s): %s\n' "$d" "$lns"
    done
    maxn="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE '[0-9]+' | sed 's/^0*//' | sort -n | tail -1)"
    hint "renumber the later duplicate to $(printf 'ADR-%04d' "$((maxn + 1))") and rename its file to match — never reuse a number. See $DOCS_REL/adr/README.md and $DOCS_REL/runbooks/collaboration.md §6."
  else
    pass "no duplicate ADR numbers"
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
  bad="$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      if ($0 !~ /^[[:space:]]*\|/) { inrow = 0; statuscol = 0; next }   # left a table
      ishdr = 0; isstep = 0; issub = 0
      for (i = 1; i <= NF; i++) {
        c = trim($i)
        if (c == "Status") { ishdr = 1; statuscol = i }
        if (c == "STEP") isstep = 1
        if (c == "Substep") issub = 1
      }
      if (ishdr && isstep) tablekind = "STEP"
      if (ishdr && issub)  tablekind = "SUB"
      if (ishdr) { inrow = 1; next }
      if (!inrow || statuscol == 0) next
      sc = trim($statuscol)
      if (sc == "" || sc ~ /^:?-+:?$/) next                            # blank or separator row
      if (sc != "Planned" && sc != "In progress" && sc != "Done" && sc != "Deferred" && sc != "Abandoned" && sc != "N/A")
        print trim($2) " -> \"" sc "\""
      else if (sc == "N/A" && tablekind != "SUB")
        print trim($2) " -> \"N/A\" (only substeps may use N/A)"
    }
  ' "$INDEX")"
  if [ -n "$bad" ]; then
    fail "invalid status value(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$bad"
    hint "use exactly one of: Planned · In progress · Done · Deferred · Abandoned (a substep may also be N/A). See $DOCS_REL/METHOD.md §1."
  else
    pass "all statuses valid"
  fi
else
  warn "no prompts/STEP-index.md yet — skipping status check"
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
  pass "no $DOCS_REL/overview.md yet (project not initialized?) — skipping legacy local user profile check"
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
  allow=" CLAUDE.md AGENTS.md init.sh doctor.sh .git .gitignore .gitattributes .DS_Store .claude .throughstone Code prompts Upcoming Prompts "
  stray=""
  for entry in "$ROOT"/* "$ROOT"/.[!.]*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    case "$allow" in *" $name "*) : ;; *) stray="$stray $name" ;; esac
  done
  if [ -n "$stray" ]; then
    warn "unexpected entr(ies) at workspace root:$stray — should these be inside a repo (usually the docs hub)?"
    hint "move durable content into a repo (almost always Code/<project>-docs/); the root holds only per-machine pointers, the repo folders, and Upcoming Prompts/. See $DOCS_REL/METHOD.md §7."
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
        fail "$b does not instruct the agent to write architecture/${prefix}-… in its Output section"
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
if [ ${#conditional_templates[@]} -eq 0 ]; then
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

# --- 10. Check-in cadence marker (overview.md) --------------------------------
hdr "10. Check-in cadence marker ($DOCS_REL/overview.md)"
# The optional `<!-- CHECK-IN-CADENCE: N -->` line in overview.md sets the check-in target N
# (status.sh defaults to 20 when the line is absent). Warn — never fail — if the line is present
# but N isn't a positive integer; its absence is always fine.
if [ -f "$OVERVIEW" ]; then
  if ! grep -qE 'CHECK-IN-CADENCE:' "$OVERVIEW"; then
    pass "no CHECK-IN-CADENCE line — status.sh uses the default cadence of 20"
  elif grep -qE 'CHECK-IN-CADENCE:[[:space:]]*[1-9][0-9]*([[:space:]]|-->|$)' "$OVERVIEW"; then
    pass "CHECK-IN-CADENCE is a positive integer"
  else
    warn "$DOCS_REL/overview.md CHECK-IN-CADENCE is not a positive integer — status.sh falls back to the default (20):"
    printf '         %s\n' "$(grep -E 'CHECK-IN-CADENCE:' "$OVERVIEW" | head -1)"
    hint "set it to a positive whole number of STEPs (e.g. <!-- CHECK-IN-CADENCE: 20 -->), or delete the line to accept the default."
  fi
else
  pass "no $DOCS_REL/overview.md yet (project not initialized?) — skipping check-in cadence check"
fi

# --- 11. Repo registry (registries/repos.yml) — check-in only ------------------
# Deliberately minimal, and deliberately not run on every invocation. The registry changes when
# a repo is created, adopted or split out; the doctor runs constantly during STEPS. Validating
# the rare path on the common one is what this check used to do, at 285 lines.
#
# What is left is the part a machine is genuinely better at than a person: noticing that a repo
# has no remote, so the work lives on exactly one laptop. A malformed row is fixed by whoever
# just edited it — see runbooks/register-repo.md, which raises anything that did not work.
#
# A row is covered by its own remote:, or by the root repository's remote when it lives inside it.
# In the mono-repo-for-now layout one row has `location: "."` and every other row is a folder in
# that one repository — whatever backs the root up backs them up too, so only the root row is
# named. The root row is covered by nothing else: if it has no remote, it is flagged like any
# other repo.
if [ "$CHECK_IN" -eq 1 ]; then
  hdr "11. Repo registry ($DOCS_REL/registries/repos.yml)"
  if [ ! -f "$REPOS_REGISTRY" ]; then
    warn "no $DOCS_REL/registries/repos.yml — skipping repo registry check"
  else
    # Walk each `- name:` block and report the rows missing a location, and the rows no
    # recorded remote covers. Comment lines are skipped, so the example row at the bottom is not
    # counted. A row is found by its `- name:` line, so a row without one is not a row at all.
    reg_flat="$(awk '
      function val(t) { sub(/^[^:]*:[[:space:]]*"?/, "", t); sub(/"?[[:space:]]*$/, "", t); return t }
      function stash() {
        if (!have) return
        n++; names[n] = name; locs[n] = loc; rems[n] = rem
        if (loc == ".") root = 1
        have = 0
      }
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*-[[:space:]]*name:/ { stash(); name = val($0); loc = ""; rem = ""; have = 1; next }
      /^[[:space:]]*location:/ { loc = val($0) }
      /^[[:space:]]*remote:/   { rem = val($0) }
      END {
        stash()
        for (i = 1; i <= n; i++) {
          if (locs[i] == "") print "location\t" names[i]
          # Covered by its own remote, or by the remote of a row at "." that contains it.
          # The location travels with the name: the fix is to push that repo, and a name alone
          # does not say where it is.
          if (rems[i] == "" && !(root && locs[i] != ".")) print "remote\t" names[i] "\t" locs[i]
        }
      }
    ' "$REPOS_REGISTRY")"

    rows="$(awk '/^[[:space:]]*#/ { next } /^[[:space:]]*-[[:space:]]*name:/ { n++ } END { print n + 0 }' "$REPOS_REGISTRY")"
    no_loc="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "location" { print $2 }')"
    no_rem="$(printf '%s\n' "$reg_flat" | awk -F'\t' '$1 == "remote"   { print $2 " (" $3 ")" }')"

    if [ -n "$no_loc" ]; then
      fail "row(s) with no location: $(printf '%s' "$no_loc" | tr '\n' ' ')"
      hint "give every row a location: — the workspace-relative path the repo lives at; without one, nothing can find the repo."
    fi
    if [ -n "$no_rem" ]; then
      warn "repo(s) with no remote: $(printf '%s' "$no_rem" | tr '\n' ' ')"
      hint "a repo with no remote lives on one machine — a bus factor of one. Push it somewhere and record the URL in remote:, or accept the risk deliberately."
    fi
    [ -z "$no_loc" ] && [ -z "$no_rem" ] && pass "$rows row(s): all have a location, and a recorded remote covers every one"
  fi
else
  hdr "11. Repo registry ($DOCS_REL/registries/repos.yml)"
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
