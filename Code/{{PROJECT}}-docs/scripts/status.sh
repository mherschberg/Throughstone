#!/usr/bin/env bash
#
# status.sh — mechanically run the next-action helper for METHOD.md §10 and print where the
# project is, what to do next, and the check-in cadence. Read-only. It reads the kickoff marker
# in overview.md and the roadmap in prompts/STEP-index.md — the same disk state the resolver
# uses — so a fresh chat (or a new teammate) can answer "what do I do next?" without guessing.
#
# This is a *helper*: METHOD.md §10 remains authoritative. When the index can't determine the
# answer, the script says so and points there.
#
# Usage:  from anywhere — Code/<project>-docs/scripts/status.sh

set -uo pipefail

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"

# File assumptions: the generated docs repo sits at Code/<project>-docs/, while the runtime
# STEP index lives at the project root in prompts/STEP-index.md.
#
# THROUGHSTONE_STEP_INDEX is a maintainer-test seam for fixtures. Generated projects should
# leave it unset and read the canonical prompts index.
INDEX="${THROUGHSTONE_STEP_INDEX:-$ROOT/prompts/STEP-index.md}"
OVERVIEW="$DOCS_DIR/overview.md"

echo "Throughstone status — $ROOT"
echo

# --- Kickoff gate (AGENTS.md "First action") ----------------------------------
if [ -f "$OVERVIEW" ] && grep -q 'PROJECT-STATUS: not-started' "$OVERVIEW"; then
  echo "Where you are:  kickoff not started (overview.md marker: not-started)."
  echo
  echo "Next action:"
  echo "  → start the kickoff — open the project and say:  \"Read AGENTS.md and follow it.\""
  echo "    It runs BOOTSTRAP-PROMPT.md from Stage 0 (no command to paste)."
  exit 0
fi

if [ ! -f "$INDEX" ]; then
  echo "Where you are:  project not initialized (no prompts/STEP-index.md)."
  echo
  echo "Next action:"
  echo "  → run ./init.sh, then \"Read AGENTS.md and follow it\" to begin the kickoff."
  exit 0
fi

# --- Parse the index into STEP rows and STEP-1 substep rows --------------------
# Locate each table's columns from its header, then emit normalized pipe-delimited records:
#   STEP|STEP-N|Status|Title
#   SUB|N.M[a]|Status|Session
# The parser depends on Markdown table headers, not fixed column positions, and ignores comments
# so dormant scaffold examples do not affect generated-project status.
parsed="$(awk -F'|' '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  {
    if (in_comment) {
      if ($0 ~ /-->/) in_comment = 0
      next
    }
    if ($0 ~ /<!--/) {
      if ($0 !~ /-->/) in_comment = 1
      next
    }
  }
  /^[[:space:]]*\|/ {
    isstep = 0; issub = 0
    for (i = 1; i <= NF; i++) {
      c = trim($i)
      if (c == "STEP")    { isstep = 1; stepcol = i }
      if (c == "Substep") { issub  = 1; subcol  = i }
      if (c == "Title")   { titlecol   = i }
      if (c == "Session") { sessioncol = i }
      if (c == "Status")  { scol = i }
    }
    if (isstep) { mode = "step"; statuscol = scol; next }
    if (issub)  { mode = "sub";  statuscol = scol; next }
    if (mode == "" || statuscol == 0) next
    st = trim($statuscol)
    if (st == "" || st ~ /^:?-+:?$/) next
    if (mode == "step") {
      id = trim($stepcol);    if (id ~ /^STEP-[0-9]+$/)            print "STEP|" id "|" st "|" trim($titlecol)
    } else {
      id = trim($subcol);     if (id ~ /^[0-9]+\.[0-9]+[a-z]?$/)   print "SUB|"  id "|" st "|" trim($sessioncol)
    }
  }
' "$INDEX")"

# Parallel indexed arrays preserve row shape while staying compatible with bash 3.2 (stock
# macOS has no associative arrays). For each i, step_id/st/ti or sub_id/st/se is one record.
step_id=(); step_st=(); step_ti=()
sub_id=(); sub_st=(); sub_se=()
while IFS='|' read -r kind id st extra; do
  [ -z "${kind:-}" ] && continue
  if [ "$kind" = "STEP" ]; then
    step_id+=("$id"); step_st+=("$st"); step_ti+=("$extra")
  elif [ "$kind" = "SUB" ]; then
    sub_id+=("$id"); sub_st+=("$st"); sub_se+=("$extra")
  fi
done <<< "$parsed"

# Sortable key for a substep id: 1.6a -> 100600+ord('a'); 1.14 -> 101400.
# Lettered conditional substeps therefore sort after their base numeric slot and before later
# numeric sessions, matching the STEP-1 table order.
subkey() {
  local maj="${1%%.*}" rest="${1#*.}" num suffix lo=0
  num="${rest%%[a-z]*}"; suffix="${rest#"$num"}"
  [ -n "$suffix" ] && lo=$(printf '%d' "'$suffix")
  echo $(( maj * 100000 + num * 100 + lo ))
}

# --- STEP-1 substep state -----------------------------------------------------
# Track the first runnable architecture substep. Final statuses count as complete; unknown
# statuses stop normal resolution and point the maintainer back to validation.
total_sub=${#sub_id[@]}; done_sub=0; unknown_sub=0; lowsub=""; lowsub_se=""; lowkey=99999999
i=0
while [ "$i" -lt "$total_sub" ]; do
  s="${sub_id[$i]}"
  case "${sub_st[$i]}" in
    Done|Deferred|N/A) done_sub=$((done_sub + 1)) ;;
    Planned|"In progress")
      k=$(subkey "$s"); if [ "$k" -lt "$lowkey" ]; then lowkey=$k; lowsub=$s; lowsub_se="${sub_se[$i]}"; fi ;;
    *) unknown_sub=$((unknown_sub + 1)) ;;
  esac
  i=$((i + 1))
done

# --- Main STEP state ----------------------------------------------------------
# Scan implementation STEPs once and retain the lowest-numbered candidate in each resolver
# bucket: active STEP, planned conditional follow-up, and ordinary planned STEP.
maxnum=0; have_impl=0; nonfinal=0; last_ci=0; step1_st=""
inprog=""; inprog_ti=""; inprog_n=999999
lowplanned_cond=""; lowplanned_cond_ti=""; lowplanned_cond_n=999999
lowplanned=""; lowplanned_ti=""; lowplanned_n=999999
n_steps=${#step_id[@]}; i=0
while [ "$i" -lt "$n_steps" ]; do
  id="${step_id[$i]}"; st="${step_st[$i]}"; ti="${step_ti[$i]}"; n=${id#STEP-}
  [ "$id" = "STEP-1" ] && step1_st="$st"
  [ "$n" -gt "$maxnum" ] && maxnum=$n
  [ "$n" -ge 2 ] && have_impl=1
  if [ "$st" = "In progress" ] && [ "$n" -lt "$inprog_n" ]; then inprog_n=$n; inprog=$id; inprog_ti="$ti"; fi
  if [ "$n" -ge 2 ] && [ "$st" = "Planned" ] &&
     printf '%s' "$ti" | grep -qiE '^conditional session:' &&
     [ "$n" -lt "$lowplanned_cond_n" ]; then
    lowplanned_cond_n=$n; lowplanned_cond=$id; lowplanned_cond_ti="$ti"
  fi
  if [ "$n" -ge 2 ] && [ "$st" = "Planned" ] && [ "$n" -lt "$lowplanned_n" ]; then lowplanned_n=$n; lowplanned=$id; lowplanned_ti="$ti"; fi
  case "$st" in Done|Deferred|Abandoned) ;; *) nonfinal=1 ;; esac
  if printf '%s' "$ti" | grep -qiE 'check.?in'; then [ "$n" -gt "$last_ci" ] && last_ci=$n; fi
  i=$((i + 1))
done
all_final=0; [ "$nonfinal" -eq 0 ] && [ "$n_steps" -gt 0 ] && all_final=1

# --- Resolve (METHOD.md §10, first match wins) --------------------------------
# First-match precedence is intentional:
# - open STEP-1 substeps come before implementation planning;
# - active ordinary or conditional STEPs beat planned follow-up conditional STEPs;
# - planned conditional follow-ups beat ordinary planned implementation STEPs.
where=""; next=""
if [ "$unknown_sub" -gt 0 ]; then
  where="Architecture (STEP-1) has ${unknown_sub} substep(s) with an unrecognized status."
  next="run scripts/check.sh and fix any invalid STEP-1 substep statuses, then re-run status.sh."
elif [ -n "$lowsub" ]; then                                 # §10.1 / §10.2
  where="Architecture (STEP-1) in progress — ${done_sub}/${total_sub} substeps complete."
  # Identify the Cross-Cutting Review by its Session-column label, not a hardcoded number.
  # Adding a standard session shifts the review. Check the lettered-conditional case
  # first so a conditional is never mistaken for the review.
  if [[ "$lowsub" =~ [a-z]$ ]]; then
    cond_example="run the conditional session by name"
    if printf '%s' "$lowsub_se" | grep -qiE 'identity|auth'; then
      cond_example="run the identity-auth session"
    elif printf '%s' "$lowsub_se" | grep -qiE 'native|mobile|desktop'; then
      cond_example="run the native-app session"
    elif printf '%s' "$lowsub_se" | grep -qiE 'privacy|compliance|data governance'; then
      cond_example="run the privacy session"
    fi
    next="run the conditional session for substep ${lowsub} — \"${lowsub_se}\"; invoke it BY NAME (e.g. \"${cond_example}\"), not by number."
  elif printf '%s' "$lowsub_se" | grep -qiE 'cross.?cutting'; then
    next="run session ${lowsub} — the Cross-Cutting Review."
  else
    next="run session ${lowsub}  (${lowsub_se})."
  fi
elif [ "$total_sub" -gt 0 ] && [ "$done_sub" -lt "$total_sub" ]; then
  where="Architecture (STEP-1) has ${done_sub}/${total_sub} substeps final, but no runnable open substep could be resolved."
  next="run scripts/check.sh and fix any invalid STEP-1 substep statuses, then re-run status.sh."
elif [ "$have_impl" -eq 0 ]; then                           # §10.3 (or STEP-1 not yet run)
  if [ "$total_sub" -gt 0 ]; then
    where="Architecture (STEP-1) complete (${done_sub}/${total_sub} substeps); implementation not yet outlined."
    next="run the planning session — it outlines the Phase-1 implementation STEPs (templates/planning-session.md)."
  elif [ "$step1_st" = "Done" ]; then
    where="STEP-1 done; implementation not yet outlined."
    next="run the planning session — it outlines the Phase-1 implementation STEPs."
  else
    where="Architecture (STEP-1) not yet run."
    next="run session 1.1 — start the architecture STEP."
  fi
elif [ -n "$inprog" ]; then                                 # §10.6
  where="Building — ${inprog} (${inprog_ti}) is In progress."
  if printf '%s' "$inprog_ti" | grep -qiE '^conditional session:'; then
    next="open ${inprog}'s thin PLAN in \"Upcoming Prompts/\" and invoke its conditional template BY NAME. Then run its architecture-consistency review, archive it, and mark ${inprog} Done."
  else
    next="open ${inprog}'s PLAN in \"Upcoming Prompts/\" and run its lowest open substep (\"run substep N.M\"). When the last is done: review, archive to prompts/, mark ${inprog} Done."
  fi
elif [ -n "$lowplanned_cond" ]; then                        # §10.4
  where="Architecture follow-up required — ${lowplanned_cond} (${lowplanned_cond_ti}) is Planned."
  next="start ${lowplanned_cond} before ordinary implementation work — author its thin one-substep PLAN pointing to the matching conditional-*.md template, record the exact by-name invocation and output-doc number, then run it in a fresh chat."
elif [ -n "$lowplanned" ]; then                             # §10.5
  where="Building — no STEP In progress; next up is ${lowplanned} (${lowplanned_ti})."
  next="start ${lowplanned} — confirm scope, then author its PLAN + substep prompts (prompts/README.md recipe) in a fresh chat."
elif [ "$all_final" -eq 1 ]; then                           # §10.8
  where="Every STEP in the index is final (Done, Deferred, or Abandoned)."
  next="phase looks complete — it's a milestone: prompt release notes (templates/release-notes-template.md if yes) + user-facing doc updates (METHOD §5), then open the next phase and run the planning session for it."
else
  where="Indeterminate from the index alone."
  next="resolve by hand via the next-action resolver in METHOD.md §10."
fi

# --- Check-in cadence (METHOD.md §10.7) ---------------------------------------
# Cadence is measured by highest indexed STEP minus the latest STEP whose title looks like a
# check-in. The helper reports the 10-20 STEP window; METHOD.md remains authoritative.
if [ "$last_ci" -gt 0 ]; then
  since=$(( maxnum - last_ci ))
  if   [ "$since" -ge 20 ]; then ci="last at STEP-${last_ci}, ${since} STEPs ago — OVERDUE (>20); insert a Check-in STEP now."
  elif [ "$since" -ge 10 ]; then ci="last at STEP-${last_ci}, ${since} STEPs ago — DUE (you're in the 10–20 window)."
  else ci="last at STEP-${last_ci}, ${since} STEPs ago — ~$(( 10 - since ))–$(( 20 - since )) STEPs of headroom."
  fi
elif [ "$maxnum" -ge 10 ]; then
  ci="no Check-in STEP yet — consider one (${maxnum} STEPs in; cadence is ~10–20)."
else
  ci="no Check-in STEP yet — fine (${maxnum} STEP(s) in; first due ~STEP-10–20)."
fi

# --- Output -------------------------------------------------------------------
echo "Where you are:"
echo "  $where"
echo
echo "Next action:"
echo "  → $next"
echo "  (start a fresh chat for it — state lives on disk, not in this conversation.)"
echo
echo "Check-in cadence:"
echo "  $ci"
