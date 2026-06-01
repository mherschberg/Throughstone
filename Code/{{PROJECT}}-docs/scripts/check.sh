#!/usr/bin/env bash
#
# check.sh — a "doctor" for a Throughstone project. It runs the mechanical integrity checks
# the method otherwise trusts prose (and the agent's memory) to enforce. Read-only: it never
# modifies a file. Safe to run anytime — intended for the periodic check-in (runbooks/check-in.md)
# and for CI.
#
# Checks:
#   1. No duplicate STEP numbers in prompts/STEP-index.md
#   2. No duplicate ADR numbers in adr/README.md
#   3. STEP / substep statuses are from the allowed set
#   4. Every architecture/NN-*.md carries Version / Status / Version Log
#   5. The ADR registry and the ADR files on disk match (both directions)
#   6. (multi-repo only) No stray files at the workspace root
#
# Usage:  from anywhere — Code/<project>-docs/scripts/check.sh
# Exit:   non-zero if any hard check FAILs; warnings alone do not fail the run.

set -uo pipefail

# This script lives in <workspace>/Code/<project>-docs/scripts/ — derive the paths.
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"
INDEX="$ROOT/prompts/STEP-index.md"
ADR_INDEX="$DOCS_DIR/adr/README.md"
ARCH_DIR="$DOCS_DIR/architecture"
ADR_DIR="$DOCS_DIR/adr"

shopt -s nullglob

fails=0
warns=0
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
hdr "3. Statuses valid (Planned · In progress · Done · Abandoned · N/A)"
if [ -f "$INDEX" ]; then
  # Find each table's Status column from its header row, then validate that cell in data rows.
  bad="$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      if ($0 !~ /^[[:space:]]*\|/) { inrow = 0; statuscol = 0; next }   # left a table
      ishdr = 0
      for (i = 1; i <= NF; i++) if (trim($i) == "Status") { ishdr = 1; statuscol = i }
      if (ishdr) { inrow = 1; next }
      if (!inrow || statuscol == 0) next
      sc = trim($statuscol)
      if (sc == "" || sc ~ /^:?-+:?$/) next                            # blank or separator row
      if (sc != "Planned" && sc != "In progress" && sc != "Done" && sc != "Abandoned" && sc != "N/A")
        print trim($2) " -> \"" sc "\""
    }
  ' "$INDEX")"
  if [ -n "$bad" ]; then
    fail "invalid status value(s):"
    while IFS= read -r line; do printf '         %s\n' "$line"; done <<< "$bad"
    hint "use exactly one of: Planned · In progress · Done · Abandoned (a substep may also be N/A). See METHOD.md §1."
  else
    pass "all statuses valid"
  fi
else
  warn "no prompts/STEP-index.md yet — skipping status check"
fi

# --- 4. Architecture-doc frontmatter ------------------------------------------
hdr "4. Architecture docs carry Version / Status / Version Log"
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
    hint "add the missing field(s) from templates/architecture-doc.md (Version / Status header, and a Version Log table). See METHOD.md §6."
  fi
fi

# --- 5. ADR registry <-> files on disk ----------------------------------------
hdr "5. ADR registry matches ADR files on disk (both directions)"
if [ -f "$ADR_INDEX" ]; then
  reg_ids="$(grep -oE '^\|[[:space:]]*ADR-[0-9]+' "$ADR_INDEX" | grep -oE 'ADR-[0-9]+')"
  disk_ids=""
  for f in "$ADR_DIR"/ADR-*.md; do disk_ids="$disk_ids$(basename "$f" | grep -oE 'ADR-[0-9]+')"$'\n'; done
  missing_files="$(comm -23 <(emit "$reg_ids") <(emit "$disk_ids"))"   # in registry, no file
  missing_rows="$(comm -13 <(emit "$reg_ids") <(emit "$disk_ids"))"    # file, not in registry
  ok=1
  [ -n "$missing_files" ] && { fail "in registry but no file: $(echo "$missing_files" | tr '\n' ' ')"; ok=0; hint "create the ADR file(s) from templates/adr.md, or remove the stale registry row(s) in adr/README.md."; }
  [ -n "$missing_rows" ]  && { fail "file on disk but not in registry: $(echo "$missing_rows" | tr '\n' ' ')"; ok=0; hint "add a registry row in adr/README.md for the file(s), or delete the file if it shouldn't exist."; }
  [ "$ok" -eq 1 ] && pass "registry and files agree ($(emit "$reg_ids" | grep -c . ) ADR(s))"
else
  warn "no adr/README.md — skipping ADR registry/disk check"
fi

# --- 6. Workspace-root hygiene (multi-repo only) ------------------------------
hdr "6. Workspace-root hygiene (multi-repo only)"
if [ -e "$ROOT/.git" ]; then
  pass "workspace root is itself a repo (mono-repo or the template) — hygiene rule relaxed; skipping"
else
  allow=" CLAUDE.md AGENTS.md init.sh .git .gitignore .gitattributes .DS_Store .claude Code prompts Upcoming Prompts "
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

# --- Summary ------------------------------------------------------------------
hdr "Summary"
printf '  %d fail(s), %d warning(s)\n' "$fails" "$warns"
if [ "$fails" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
fi
echo "  RESULT: OK"
exit 0
