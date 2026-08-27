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
#  11. registries/repos.yml rows are internally consistent (statuses, control/gap invariants)
#  12. Every repo row records who owns it, and a repo on this machine records what it provides
#  13. registries/repos.yml is shaped so the scripts that read it by line prefix stay correct
#
# Usage:  from anywhere — Code/<project>-docs/scripts/check.sh
# Exit:   non-zero if any hard check FAILs; warnings alone do not fail the run.

set -uo pipefail

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization. Derive all paths from BASH_SOURCE so the
# doctor can be run from any working directory without resolving the template placeholder.
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"
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
    hint "renumber the duplicate (the one reserved later) to STEP-$((maxn + 1)) — never reuse or delete a number; mark a row Abandoned if it won't be built. See runbooks/collaboration.md §2."
  else
    pass "no duplicate STEP numbers"
  fi
else
  warn "no prompts/STEP-index.md yet (project not initialized?) — skipping STEP checks"
fi

# --- 2. Duplicate ADR numbers -------------------------------------------------
hdr "2. Duplicate ADR numbers (adr/README.md)"
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
    hint "renumber the later duplicate to $(printf 'ADR-%04d' "$((maxn + 1))") and rename its file to match — never reuse a number. See adr/README.md and runbooks/collaboration.md §6."
  else
    pass "no duplicate ADR numbers"
  fi
else
  warn "no adr/README.md — skipping ADR-number check"
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
    hint "use exactly one of: Planned · In progress · Done · Deferred · Abandoned (a substep may also be N/A). See METHOD.md §1."
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
    hint "add the missing field(s) from templates/architecture-doc-template.md (Version / Status header, and a Version Log table). See METHOD.md §6."
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
  [ -n "$missing_files" ] && { fail "in registry but no file: $(echo "$missing_files" | tr '\n' ' ')"; ok=0; hint "create the ADR file(s) from templates/adr-template.md, or remove the stale registry row(s) in adr/README.md."; }
  [ -n "$missing_rows" ]  && { fail "file on disk but not in registry: $(echo "$missing_rows" | tr '\n' ' ')"; ok=0; hint "add a registry row in adr/README.md for the file(s), or delete the file if it shouldn't exist."; }
  [ "$ok" -eq 1 ] && pass "registry and files agree ($(emit "$reg_ids" | grep -c . ) ADR(s))"
else
  warn "no adr/README.md — skipping ADR registry/disk check"
fi

# --- 6. Legacy local user profile fields --------------------------------------
hdr "6. Legacy local user profile fields"
# In older projects, the first user's communication preferences were stored in overview.md.
# They now belong in root .throughstone/local-user.md, because each contributor has their own
# local profile. This is warning-only: doctor cannot know which human the old values represent.
if [ -f "$OVERVIEW" ]; then
  legacy_profile_fields="$(grep -nE '^## (Your experience level|Planning communication style)[[:space:]]*$' "$OVERVIEW" || true)"
  if [ -n "$legacy_profile_fields" ]; then
    warn "overview.md contains legacy personal preference section(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$legacy_profile_fields"
    hint "create/update root .throughstone/local-user.md for the active user, then remove these personal-preference sections from overview.md after confirming they are not project facts. See UPDATING-THROUGHSTONE.md."
  else
    pass "overview.md has no legacy local user preference sections"
  fi
else
  pass "no overview.md yet (project not initialized?) — skipping legacy local user profile check"
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
    hint "move durable content into a repo (almost always Code/<project>-docs/); the root holds only per-machine pointers, the repo folders, and Upcoming Prompts/. See METHOD.md §7."
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
  warn "no templates/step-index-seed.md found — skipping numbering check"
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
      fail "$b has no matching 1.$minor row in templates/step-index-seed.md"
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
        fail "templates/step-index-seed.md has 1.$seed_minor ('$seed_label') but no matching numbered session template"
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
    hint "keep numbered session files, their '(Session 1.N)' headings, and templates/step-index-seed.md rows in lockstep; the Cross-Cutting Review remains the final numbered session."
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
    hint "copy an existing conditional template's contract: explicit applicability, 'Run it by name', Output, Next, and both STEP-1 / late-follow-up PLAN, architecture-index, and active-substep bookkeeping. See METHOD.md §4."
  fi
fi

# --- 10. Check-in cadence marker (overview.md) --------------------------------
hdr "10. Check-in cadence marker (overview.md)"
# The optional `<!-- CHECK-IN-CADENCE: N -->` line in overview.md sets the check-in target N
# (status.sh defaults to 20 when the line is absent). Warn — never fail — if the line is present
# but N isn't a positive integer; its absence is always fine.
if [ -f "$OVERVIEW" ]; then
  if ! grep -qE 'CHECK-IN-CADENCE:' "$OVERVIEW"; then
    pass "no CHECK-IN-CADENCE line — status.sh uses the default cadence of 20"
  elif grep -qE 'CHECK-IN-CADENCE:[[:space:]]*[1-9][0-9]*([[:space:]]|-->|$)' "$OVERVIEW"; then
    pass "CHECK-IN-CADENCE is a positive integer"
  else
    warn "overview.md CHECK-IN-CADENCE is not a positive integer — status.sh falls back to the default (20):"
    printf '         %s\n' "$(grep -E 'CHECK-IN-CADENCE:' "$OVERVIEW" | head -1)"
    hint "set it to a positive whole number of STEPs (e.g. <!-- CHECK-IN-CADENCE: 20 -->), or delete the line to accept the default."
  fi
else
  pass "no overview.md yet (project not initialized?) — skipping check-in cadence check"
fi

# --- 11-13. Repo registry (registries/repos.yml) ------------------------------
# The registry is read by scripts that match line prefixes and know nothing about YAML nesting
# (setup-workspace.sh's clone loop, init.sh's remote recorder), so three things are worth
# checking: what a row says (11), whether its control record was ever filled in (12), and
# whether the file is shaped so those readers stay correct (13). Nothing here reads another
# repository's contents — that stays with the check-in; 12 only asks git whether a location is
# the root of a work tree.
#
# registry_rows FILE flattens the registry once for all three. One tab-separated record per
# meaningful line inside a row block:
#     row-number  line-number  class  parent  key  value
# class is head (the `- name:` line), field (row level), nested (deeper than row level), or
# other (a line that is not `key: value` at all — a continuation of a multi-line value).
# Comment lines are skipped, which is the registry's own rule 3: the example row is commented
# out one `#` per line and is documentation, not data.
registry_rows() {
  awk '
    BEGIN { SQ = sprintf("%c", 39) }
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
    function clean(v) {
      # A trailing `# ...` comment is stripped only from values carrying no quote and no brace,
      # so a quoted description or a flow mapping containing a "#" is never truncated.
      if (v !~ /["{]/ && index(v, SQ) == 0) sub(/[[:space:]]+#.*$/, "", v)
      sub(/[[:space:]]+$/, "", v)
      if (v ~ /^".*"$/) return substr(v, 2, length(v) - 2)
      if (length(v) > 1 && substr(v, 1, 1) == SQ && substr(v, length(v), 1) == SQ)
        return substr(v, 2, length(v) - 2)
      return v
    }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*-[[:space:]]*name:/ {
      # The row block starts here, and its field indent is the column the name starts in.
      rown++
      base = index($0, "name:") - 1
      parent = ""
      printf "%d\t%d\thead\t\tname\t%s\n", rown, NR, clean(ltrim(substr($0, index($0, "name:") + 5)))
      next
    }
    rown == 0 { next }
    {
      ind = match($0, /[^ \t]/) - 1
      t = ltrim($0)
      if (ind < base) {
        # Dedenting a line out of the row block does not put it out of reach: the readers match
        # line prefixes at any indent, so a `location:` at column 0 below the last row is read
        # as the location of that row, exactly as a nested one is. Reported, not skipped.
        if (t ~ /^[A-Za-z_][A-Za-z0-9_-]*:([[:space:]]|$)/) {
          k = t; sub(/:.*$/, "", k)
          printf "%d\t%d\tstray\t\t%s\t\n", rown, NR, k
        }
        next
      }
      if (t ~ /^[A-Za-z_][A-Za-z0-9_-]*:([[:space:]]|$)/) {
        k = t; sub(/:.*$/, "", k)
        v = t; sub(/^[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]*/, "", v)
        if (ind == base) { parent = k; printf "%d\t%d\tfield\t\t%s\t%s\n", rown, NR, k, clean(v) }
        else             { printf "%d\t%d\tnested\t%s\t%s\t%s\n", rown, NR, parent, k, clean(v) }
      } else {
        printf "%d\t%d\tother\t%s\t\t%s\n", rown, NR, parent, t
      }
    }
  ' "$1"
}

REG_PRESENT=0
REG_FLAT=""
if [ -f "$REPOS_REGISTRY" ]; then
  REG_PRESENT=1
  REG_FLAT="$(registry_rows "$REPOS_REGISTRY")"
fi

hdr "11. Repo registry record consistency (registries/repos.yml)"
# Invariant: a row says one thing about itself. This reads the file only — no filesystem — so it
# holds everywhere check.sh runs, CI included, and it is the half that carries the control model:
# control is permission, so a managed repo cannot also record an unmet need.
if [ "$REG_PRESENT" -eq 0 ]; then
  warn "no registries/repos.yml — skipping repo registry checks"
  hint "every project ships registries/; restore the directory from the scaffold, or re-run bootstrap for a project created with --registries=no."
else
  reg_bad="$(printf '%s\n' "$REG_FLAT" | awk -F'\t' '
    BEGIN { SQ = sprintf("%c", 39) }
    # provides: entries are flow mappings, so status and note are read out of one line.
    function fmhas(s, key) { return (s ~ (key ":")) }
    function fmval(s, key,   t, q) {
      t = s
      sub(".*" key ":[[:space:]]*", "", t)
      q = substr(t, 1, 1)
      if (q == "\"" || q == SQ) { t = substr(t, 2); sub(q ".*$", "", t); return t }
      sub(/[,}].*$/, "", t)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
      return t
    }
    $3 == "head" { nm[$1] = $6; if ($1 + 0 > maxr) maxr = $1 + 0 }
    $3 == "field" && $5 == "origin"  { org[$1] = $6; orgln[$1] = $2 }
    $3 == "field" && $5 == "control" { ctl[$1] = $6; ctlln[$1] = $2 }
    $3 == "nested" && $4 == "provides" { pv[$1 SUBSEP $5] = $6; pl[$1 SUBSEP $5] = $2; pk[$1] = pk[$1] " " $5 }
    END {
      split("created adopted", a, " ");            for (i in a) okorg[a[i]] = 1
      split("managed external", b, " ");           for (i in b) okctl[b[i]] = 1
      split("ours extended theirs gap", c, " "); for (i in c) okst[c[i]] = 1
      for (r = 1; r <= maxr; r++) {
        if ((r in org) && !(org[r] in okorg))
          printf "line %d: %s -> origin: \"%s\" is not created or adopted\n", orgln[r], nm[r], org[r]
        if ((r in ctl) && !(ctl[r] in okctl))
          printf "line %d: %s -> control: \"%s\" is not managed or external\n", ctlln[r], nm[r], ctl[r]
        n = split(pk[r], keys, " ")
        for (j = 1; j <= n; j++) {
          k = keys[j]; v = pv[r SUBSEP k]; ln = pl[r SUBSEP k]
          if (!fmhas(v, "status")) {
            printf "line %d: %s -> provides: %s carries no status\n", ln, nm[r], k
            continue
          }
          st = fmval(v, "status")
          if (!(st in okst)) {
            printf "line %d: %s -> provides: %s status \"%s\" is not ours/extended/theirs/gap\n", ln, nm[r], k, st
            continue
          }
          note = fmhas(v, "note") ? fmval(v, "note") : ""
          if (st == "gap" && note == "")
            printf "line %d: %s -> provides: %s is a gap and carries no note saying why\n", ln, nm[r], k
          if ((r in ctl) && ctl[r] == "managed" && st == "gap")
            printf "line %d: %s -> control: managed with a gap in %s\n", ln, nm[r], k
          if ((r in ctl) && ctl[r] == "external" && (st == "ours" || st == "extended"))
            printf "line %d: %s -> control: external with %s in %s\n", ln, nm[r], st, k
        }
      }
    }
  ')"
  if [ -n "$reg_bad" ]; then
    fail "inconsistent repo registry row(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$reg_bad"
    hint "make each row say one thing: a managed repo has no gap (either the need is met, or the repo is external), an external repo has no ours/extended, and a gap says why. See the schema at the top of registries/repos.yml."
  else
    reg_rows="$(printf '%s\n' "$REG_FLAT" | awk -F'\t' '$3 == "head"' | grep -c . || true)"
    pass "$reg_rows row(s) consistent: statuses, control/gap invariants, note on gap"
  fi
fi

hdr "12. Repo registry control record (registries/repos.yml)"
# Invariant: every row records who owns the repo, and a row that is actually a repository on
# this machine records what it already provides. Absence is a WARN, not a FAIL: it means the
# record was never filled in, and nothing on disk says when the project was created, so absence
# cannot be read as age. A row whose location is not on this machine is skipped and counted —
# staying silent about it is indistinguishable from a pass.
if [ "$REG_PRESENT" -eq 0 ]; then
  pass "no registries/repos.yml — nothing to check (reported in check 11)"
else
  reg_summary="$(printf '%s\n' "$REG_FLAT" | awk -F'\t' '
    $3 == "head" { nm[$1] = $6; if ($1 + 0 > maxr) maxr = $1 + 0 }
    $3 == "field" && $5 == "location" { loc[$1] = $6 }
    $3 == "field" && $5 == "origin"   { org[$1] = $6 }
    $3 == "field" && $5 == "control"  { ctl[$1] = $6 }
    $3 == "nested" && $4 == "provides" { pk[$1] = pk[$1] " " $5 }
    END { for (r = 1; r <= maxr; r++) printf "%s\t%s\t%s\t%s\t%s\n", nm[r], loc[r], org[r], ctl[r], pk[r] }
  ')"
  reg_incomplete=""
  reg_total=0
  reg_absent=0
  reg_here=0
  while IFS=$'\t' read -r r_name r_loc r_origin r_control r_provides; do
    [ -n "${r_name:-}" ] || continue
    reg_total=$((reg_total + 1))
    miss=""
    [ -n "${r_origin:-}" ] || miss="${miss}${miss:+; }no origin:"
    [ -n "${r_control:-}" ] || miss="${miss}${miss:+; }no control:"
    if [ -z "${r_loc:-}" ]; then
      miss="${miss}${miss:+; }no location:"
    else
      case "$r_loc" in /*) abs="$r_loc" ;; *) abs="$ROOT/$r_loc" ;; esac
      if [ ! -d "$abs" ]; then
        reg_absent=$((reg_absent + 1))
      else
        reg_here=$((reg_here + 1))
        # The work-tree-root test is the comparison itself, on physical paths both sides: a
        # trailing slash, a symlinked workspace root, a repository subdirectory and a plain
        # folder all answer correctly, and a submodule or linked worktree — where .git is a
        # file, not a directory — is still a repository.
        top="$(git -C "$abs" rev-parse --show-toplevel 2>/dev/null)"
        if [ -n "$top" ] && [ "$top" = "$(cd "$abs" && pwd -P)" ]; then
          # A repo Throughstone created carries no observation debt; a repo it adopted — or a
          # row that never said — owes all three, and the missing key is named, because the
          # register action leaves one out on purpose when it could not look.
          if [ -z "${r_origin:-}" ] || [ "$r_origin" = "adopted" ]; then
            for need in readme license ci; do
              case " ${r_provides:-} " in
                *" $need "*) : ;;
                *) miss="${miss}${miss:+; }provides: no $need" ;;
              esac
            done
          fi
        fi
      fi
    fi
    [ -n "$miss" ] && reg_incomplete="${reg_incomplete}${r_name} -> ${miss}"$'\n'
  done <<< "$reg_summary"
  reg_incomplete="${reg_incomplete%$'\n'}"
  if [ -n "$reg_incomplete" ]; then
    warn "$(printf '%s\n' "$reg_incomplete" | grep -c .) of $reg_total row(s) carry no control record, or an incomplete one:"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$reg_incomplete"
    hint "add origin: and control: to each row, and fill provides: by looking at the repo rather than by picking a status. See the schema at the top of registries/repos.yml, and UPDATING-THROUGHSTONE.md."
  elif [ "$reg_absent" -eq 0 ]; then
    pass "all $reg_total row(s) carry a complete control record"
  else
    # Claim only what was looked at: a row whose location is not here had its provides: skipped.
    pass "all $reg_total row(s) carry origin and control; provides: checked on the $reg_here here"
  fi
  [ "$reg_absent" -gt 0 ] && printf '         %d of %d row(s) not present on this machine; provides: not checked there\n' "$reg_absent" "$reg_total"
fi

hdr "13. Repo registry file shape (registries/repos.yml)"
# Invariant: the file stays readable by parsers that match line prefixes. These FAIL rather than
# warn — a violation of rule 1 is a clone into the wrong path, not a thin record. The two
# reserved-name sets are read from the registry header's own `reserved-` lines, which are the
# register of record for them; rules 3 and 5 are not here because they constrain scripts rather
# than this file, and a checker reading the registry cannot see them.
if [ "$REG_PRESENT" -eq 0 ]; then
  pass "no registries/repos.yml — nothing to check (reported in check 11)"
else
  reserved_row="$(sed -n 's/^#[[:space:]]*reserved-row-level:[[:space:]]*//p' "$REPOS_REGISTRY" | head -1)"
  reserved_nested="$(sed -n 's/^#[[:space:]]*reserved-nested:[[:space:]]*//p' "$REPOS_REGISTRY" | head -1)"
  if [ -z "$reserved_row" ] || [ -z "$reserved_nested" ]; then
    fail "registry header has no reserved-row-level: / reserved-nested: line — the reserved name sets cannot be read"
    hint "restore both lines under rule 4 at the top of registries/repos.yml, one space-separated list each; scripts/check.sh reads them by those prefixes."
  else
    # tr rather than word-splitting: an unquoted expansion here would also glob against the
    # working directory if a name ever picked up a wildcard character.
    to_lines() { printf '%s' "$1" | tr -s '[:space:]' '\n'; }
    overlap="$(comm -12 <(emit "$(to_lines "$reserved_row")") <(emit "$(to_lines "$reserved_nested")") | tr '\n' ' ')"
    reg_shape="$(printf '%s\n' "$REG_FLAT" | awk -F'\t' -v rowset="$reserved_row" -v nestset="$reserved_nested" '
      BEGIN {
        n = split(rowset, a, /[[:space:]]+/);  for (i = 1; i <= n; i++) if (a[i] != "") rowlvl[a[i]] = 1
        m = split(nestset, b, /[[:space:]]+/); for (i = 1; i <= m; i++) if (b[i] != "") nested[b[i]] = 1
      }
      $3 == "head" { nm[$1] = $6; seen[$1 SUBSEP "name"] = 1 }
      $3 == "field" {
        # Two row-level fields of one name in one block: every reader takes the last one.
        if (($1 SUBSEP $5) in seen)
          printf "1\tline %d: %s -> a second row-level %s: in the same row block\n", $2, nm[$1], $5
        seen[$1 SUBSEP $5] = 1
        if (!($5 in rowlvl))
          printf "4\tline %d: %s -> row-level field %s: is not in reserved-row-level\n", $2, nm[$1], $5
        if ($6 ~ /^[|>]/)
          printf "2\tline %d: %s -> %s: opens a block scalar; values are single-line\n", $2, nm[$1], $5
      }
      $3 == "nested" {
        if ($5 in rowlvl)
          printf "1\tline %d: %s -> nested %s: shadows a row-level field name\n", $2, nm[$1], $5
        else if (!($5 in nested))
          printf "4\tline %d: %s -> nested key %s: is not in reserved-nested\n", $2, nm[$1], $5
        if ($6 ~ /^[|>]/)
          printf "2\tline %d: %s -> %s: opens a block scalar; values are single-line\n", $2, nm[$1], $5
        if ($4 == "provides" && $6 !~ /^\{.*\}$/)
          printf "2\tline %d: %s -> provides: %s is not a flow mapping { status: ..., note: ... }\n", $2, nm[$1], $5
      }
      $3 == "other" { printf "2\tline %d: %s -> not a single-line key: value\n", $2, nm[$1] }
      $3 == "stray" {
        if ($5 in rowlvl)
          printf "1\tline %d: %s -> %s: sits outside any row block and would still be read as that row\n", $2, nm[$1], $5
      }
    ')"
    shape_ok=1
    if [ -n "$overlap" ]; then
      fail "reserved-row-level and reserved-nested share name(s): $overlap"
      shape_ok=0
    fi
    for rule in 1 2 4; do
      hits="$(printf '%s\n' "$reg_shape" | awk -F'\t' -v r="$rule" '$1 == r { print $2 }')"
      [ -n "$hits" ] || continue
      case "$rule" in
        1) fail "row-level field name(s) used where a reader would misread them (rule 1):" ;;
        2) fail "value(s) that are not single-line scalars (rule 2):" ;;
        4) fail "field name(s) missing from the registry's reserved sets (rule 4):" ;;
      esac
      while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$hits"
      shape_ok=0
    done
    if [ "$shape_ok" -eq 1 ]; then
      pass "parser rules hold: no shadowed field names, single-line values, disjoint name sets"
    else
      hint "put every value on one line (provides: entries are flow mappings), keep nested keys out of the row-level names, and add a new field to exactly one of the reserved- lines. See rules 1-5 at the top of registries/repos.yml."
    fi
  fi
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
