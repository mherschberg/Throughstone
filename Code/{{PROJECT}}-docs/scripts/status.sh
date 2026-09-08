#!/usr/bin/env bash
#
# status.sh — mechanically run the next-action helper for METHOD.md §10 and print where the
# project is, what to do next, and when the next check-in is due. Read-only. It reads the kickoff
# marker and the scheduled check-in in overview.md and the roadmap in prompts/STEP-index.md — the
# same disk state the resolver uses — so a fresh chat (or a new teammate) can answer "what do I do
# next?" without guessing.
#
# This is a *helper*: METHOD.md §10 remains authoritative. When the index can't determine the
# answer, the script says so and points there.
#
# Usage:  from anywhere — Code/<project>-docs/scripts/status.sh

set -uo pipefail

# This script takes no options. Reject anything passed rather than ignoring it, so a typo, or a
# flag meant for one of the other helpers, is a visible error instead of a silent no-op — the
# same contract check.sh already keeps. The message stays bare rather than naming a help command,
# because the helper can be reached both through ./doctor.sh and directly.
if [ "$#" -gt 0 ]; then
  echo "status.sh: unknown option: $1" >&2
  exit 2
fi

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"

# What this script prints is read from wherever it was run, and it never changes the caller's
# directory — normally that is the workspace root. So every path it names is written from there,
# the same base check.sh uses for the same reason (METHOD.md §7, "a path a tool prints follows
# the reader, not the tool"). Paths already at the workspace root — prompts/, Upcoming Prompts/ —
# are written bare; anything inside the docs hub carries this prefix.
DOCS_REL="Code/$(basename "$DOCS_DIR")"

# File assumptions: the generated docs repo sits at Code/<project>-docs/, while the runtime
# STEP index lives at the project root in prompts/STEP-index.md.
#
# THROUGHSTONE_STEP_INDEX and THROUGHSTONE_OVERVIEW are maintainer-test seams for fixtures.
# Generated projects should leave them unset and read the canonical prompts index and overview.
INDEX="${THROUGHSTONE_STEP_INDEX:-$ROOT/prompts/STEP-index.md}"
OVERVIEW="${THROUGHSTONE_OVERVIEW:-$DOCS_DIR/overview.md}"

echo "Throughstone status — $ROOT"
echo

# --- Kickoff gate (AGENTS.md "First action") ----------------------------------
if [ -f "$OVERVIEW" ] && grep -q 'PROJECT-STATUS: not-started' "$OVERVIEW"; then
  echo "Where you are:  kickoff not started ($DOCS_REL/overview.md marker: not-started)."
  echo
  echo "Next action:"
  echo "  → start the kickoff — open the project and say:  \"Read AGENTS.md and follow it.\""
  echo "    It runs $DOCS_REL/BOOTSTRAP-PROMPT.md from Stage 0 (no command to paste)."
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
# The parser depends on Markdown table headers, not fixed column positions, and ignores commented
# content so dormant scaffold examples do not affect generated-project status.
#
# Comments are STRIPPED, not skipped by line. Dropping the whole line deleted any row carrying an
# inline note — `| STEP-2 | Build | | In progress | <!-- waiting on design --> |` vanished, so the
# STEP in flight became invisible, and a note on the highest-numbered row also lost the project's
# high-water mark and made a live phase report as complete. The seeded index is full of
# instructional comments and invites annotation, so that was reachable without anyone intending a
# marker. Removing only the commented spans keeps the row and still discards example rows that sit
# wholly inside a comment block, which is what this ever needed to do.
parsed="$(awk -F'|' '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  {
    line = $0; kept = ""
    while (length(line) > 0) {
      if (in_comment) {
        p = index(line, "-->")
        if (p == 0) { line = ""; break }
        line = substr(line, p + 3); in_comment = 0
      } else {
        p = index(line, "<!--")
        if (p == 0) { kept = kept line; line = ""; break }
        kept = kept substr(line, 1, p - 1)
        line = substr(line, p + 4); in_comment = 1
      }
    }
    $0 = kept
    if ($0 ~ /^[[:space:]]*$/) next
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
maxnum=0; have_impl=0; nonfinal=0; step1_st=""
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
  i=$((i + 1))
done
all_final=0; [ "$nonfinal" -eq 0 ] && [ "$n_steps" -gt 0 ] && all_final=1

# --- Resolve (METHOD.md §10, first match wins) --------------------------------
# First-match precedence is intentional:
# - open STEP-1 substeps come before implementation planning, but only while the STEP-1 row is
#   itself open;
# - active ordinary or conditional STEPs beat planned follow-up conditional STEPs;
# - planned conditional follow-ups beat ordinary planned implementation STEPs.
where=""; next=""
if [ "$unknown_sub" -gt 0 ]; then
  where="Architecture (STEP-1) has ${unknown_sub} substep(s) with an unrecognized status."
  next="run ./doctor.sh check and fix any invalid STEP-1 substep statuses, then re-run ./doctor.sh status."
# Both substep arms are gated on the STEP-1 row: the row is what says whether architecture is
# over, and it decides in both directions. The close-out arm below reads it from the other side —
# substeps all final while the row is still open means the close-out is the work — so a Done
# STEP-1 falls through to that same pair (METHOD.md §10, whose closing rule makes the index
# authoritative for which STEP is next).
elif [ -n "$lowsub" ] && [ "$step1_st" != "Done" ]; then    # §10.1 / §10.2
  where="Architecture (STEP-1) in progress — ${done_sub}/${total_sub} substeps complete."
  # Identify the Cross-Cutting Review by its Session-column label, not a hardcoded number.
  # Adding a standard session shifts the review. Check the lettered-conditional case
  # first so a conditional is never mistaken for the review.
  #
  # These match the START of the Session label, and match the session's own name rather than a
  # loose keyword. Searching anywhere in the cell read a substep's topic as a conditional it has
  # nothing to do with: "Authoring conventions & style guide" contains auth, so it was advised as
  # "run the identity-auth session", and "Desktop publishing pipeline" as the native-app one —
  # which anchoring alone would not have fixed, since that label really does begin with desktop.
  # A label that matches nothing falls to the generic wording, which is still correct advice.
  if [[ "$lowsub" =~ [a-z]$ ]]; then
    cond_example="run the conditional session by name"
    if printf '%s' "$lowsub_se" | grep -qiE '^(identity|auth)\b'; then
      cond_example="run the identity-auth session"
    elif printf '%s' "$lowsub_se" | grep -qiE '^native\b|^(mobile|desktop) app\b'; then
      cond_example="run the native-app session"
    elif printf '%s' "$lowsub_se" | grep -qiE '^privacy\b|^data governance\b'; then
      cond_example="run the privacy session"
    fi
    next="Run STEP-${lowsub}: ${lowsub_se} — invoke it BY NAME (e.g. \"${cond_example}\"), not by number."
  elif printf '%s' "$lowsub_se" | grep -qiE '^cross.?cutting\b'; then
    next="Run STEP-${lowsub}: Cross-Cutting Review."
  else
    next="Run STEP-${lowsub}: ${lowsub_se}."
  fi
# Gated for the same reason, and the gate is load-bearing: this arm is otherwise unreachable, so
# without it a Done STEP-1 with open substeps lands here and is told to fix statuses that are valid.
elif [ "$total_sub" -gt 0 ] && [ "$done_sub" -lt "$total_sub" ] && [ "$step1_st" != "Done" ]; then
  where="Architecture (STEP-1) has ${done_sub}/${total_sub} substeps final, but no runnable open substep could be resolved."
  next="run ./doctor.sh check and fix any invalid STEP-1 substep statuses, then re-run ./doctor.sh status."
elif [ "$have_impl" -eq 0 ]; then                           # §10.3 (or STEP-1 not yet run)
  # §10.3's precondition is "STEP-1 complete", and the STEP-1 *row* is what says so: the
  # Cross-Cutting Review, the archive to prompts/, and the flip to Done all happen after the last
  # substep goes Done (templates/architecture-sessions/14-cross-cutting-review.md — the row flips
  # "once the review is clean"). While the row is still open that close-out is the work, so
  # answering "run the planning session" skips it — and §10's closing rule makes the index
  # authoritative for which STEP is next, which this arm used to contradict by reporting STEP-1
  # complete while the index said otherwise. A missing STEP-1 row leaves the old answer alone.
  if [ "$total_sub" -gt 0 ] && [ -n "$step1_st" ] &&
     [ "$step1_st" != "Done" ] && [ "$step1_st" != "Deferred" ] && [ "$step1_st" != "Abandoned" ]; then
    where="Architecture (STEP-1) — all ${total_sub} substeps are final, but the STEP-1 row is still \"${step1_st}\"."
    next="close out STEP-1 — archive it to the Phase-1 folder under prompts/ ($DOCS_REL/METHOD.md §5) and mark the STEP-1 row Done. If the Cross-Cutting Review left findings open, settle those first. The planning session comes after that."
  elif [ "$total_sub" -gt 0 ]; then
    where="Architecture (STEP-1) complete (${done_sub}/${total_sub} substeps); implementation not yet outlined."
    next="run the planning session — it outlines the Phase-1 implementation STEPs ($DOCS_REL/templates/planning-session.md)."
  elif [ "$step1_st" = "Done" ]; then
    where="STEP-1 done; implementation not yet outlined."
    next="run the planning session — it outlines the Phase-1 implementation STEPs."
  else
    where="Architecture (STEP-1) not yet run."
    next="Run STEP-1.1: System Overview, Requirements & Non-Goals — start the architecture STEP."
  fi
elif [ -n "$inprog" ]; then                                 # §10.6
  where="Building — ${inprog} (${inprog_ti}) is In progress."
  if printf '%s' "$inprog_ti" | grep -qiE '^conditional session:'; then
    next="open ${inprog}'s thin PLAN in \"Upcoming Prompts/\", identify its conditional template invocation BY NAME, and wait for that explicit by-name command. Then run its architecture-consistency review, archive it, and mark ${inprog} Done."
  else
    next="open ${inprog}'s PLAN in \"Upcoming Prompts/\", identify its lowest open substep, and wait for an explicit substep command (\"run substep N.M\"). When the last is done: review, archive to prompts/, mark ${inprog} Done."
  fi
elif [ -n "$lowplanned_cond" ]; then                        # §10.4
  where="Architecture follow-up required — ${lowplanned_cond} (${lowplanned_cond_ti}) is Planned."
  next="plan ${lowplanned_cond} before ordinary implementation work — author its thin one-substep PLAN pointing to the matching conditional-*.md template, record the exact by-name invocation and output-doc number, then stop for approval before invoking it."
elif [ -n "$lowplanned" ]; then                             # §10.5
  where="Building — no STEP In progress; next up is ${lowplanned} (${lowplanned_ti})."
  next="plan ${lowplanned} — confirm scope, author its PLAN + substep prompts (prompts/README.md recipe) in a fresh chat, then stop for approval before running any substep."
elif [ "$all_final" -eq 1 ]; then                           # §10.8
  where="Every STEP in the index is final (Done, Deferred, or Abandoned)."
  next="phase looks complete — it's a milestone: prompt release notes ($DOCS_REL/templates/release-notes-template.md if yes) + user-facing doc updates ($DOCS_REL/METHOD.md §5), then open the next phase and run the planning session for it."
else
  where="Indeterminate from the index alone."
  next="resolve by hand via the next-action resolver in $DOCS_REL/METHOD.md §10."
fi

# --- Next check-in (METHOD.md §10 rule 7) -------------------------------------
# overview.md carries `<!-- NEXT-CHECK-IN: … -->`, holding either a STEP number (`STEP-45`) or an
# ISO date (`2026-11-15`). Whoever last scheduled a check-in wrote it: the check-in itself, the
# planning session, or the user saying when. Nothing validates it — an unreadable or missing value
# reads as "none scheduled", which is an actionable state rather than an error, and is the floor
# this advice can never fall below.
#
# METHOD.md §10 rule 7 is deliberately not a resolver branch: this advises and proposes, and never
# becomes the next action, because a gate would fire mid-feature — the one place §5 says not to
# put a check-in. So it prints beside the next action, never instead of it.
nci=""
if [ -f "$OVERVIEW" ]; then
  nci="$(sed -n 's/.*NEXT-CHECK-IN:[[:space:]]*\(.*\)/\1/p' "$OVERVIEW" | head -1 \
         | sed 's/-->.*//; s/[[:space:]]*$//')"
fi
# Both forms are matched strictly, so anything else falls through to "none scheduled" instead of
# reaching the comparisons below as a fragment.
nci_step="$(printf '%s' "$nci" | grep -oE '^STEP-[0-9]+$' | grep -oE '[0-9]+$')"
nci_date="$(printf '%s' "$nci" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')"

# Where the project actually is — the STEP the next action above just named, which is what a
# scheduled STEP has to be measured against. It is NOT the highest row in the index: the planning
# session writes a whole phase of Planned rows at once, so the highest row is where the phase
# ends, and comparing against it would report every freshly-planned phase as due on its first day.
#
# This follows the resolver's own precedence rather than taking the lowest of the three, so the
# two halves of the output cannot name different STEPs: an active STEP wins, then the lowest
# Planned one, and only when every row is final (§10.8, the phase is over) is the highest row the
# position.
if   [ "$inprog_n"    -lt 999999 ]; then atstep=$inprog_n
elif [ "$lowplanned_n" -lt 999999 ]; then atstep=$lowplanned_n
else atstep=$maxnum
fi

ci_propose=""
if [ -n "$nci_step" ]; then
  # 10# forces base 10: a hand-written `STEP-08` is octal to $(( )). The normalised number is
  # what gets printed, so the line says what was read rather than what was typed.
  nci_n=$((10#$nci_step))
  if [ "$nci_n" -le "$atstep" ]; then
    ci="due — scheduled for STEP-${nci_n}, and the project is at STEP-${atstep}."; ci_propose=1
  else
    ci="next at STEP-${nci_n} (the project is at STEP-${atstep})."
  fi
elif [ -n "$nci_date" ]; then
  # ISO dates sort lexically, so this needs no date arithmetic.
  today="$(date +%F)"
  if [[ "$nci_date" > "$today" ]]; then
    ci="next on ${nci_date} (today is ${today})."
  else
    ci="due — scheduled for ${nci_date}."; ci_propose=1
  fi
elif [ -n "$nci" ]; then
  # A value that is present but unreadable is reported as itself. Nothing validates the line any
  # more, so this message is the only place a typo surfaces.
  ci="none scheduled — $DOCS_REL/overview.md's NEXT-CHECK-IN reads \"$nci\", which is neither a STEP number (STEP-45) nor a date (2026-11-15)."; ci_propose=1
else
  ci="none scheduled — add a NEXT-CHECK-IN line to $DOCS_REL/overview.md: a STEP number (STEP-45) or a date (2026-11-15)."; ci_propose=1
fi

# --- Output -------------------------------------------------------------------
echo "Where you are:"
echo "  $where"
echo
echo "Next action:"
echo "  → $next"
echo "  (start a fresh chat for it — state lives on disk, not in this conversation.)"
if [ -n "$ci_propose" ]; then
  echo
  echo "  Also worth proposing: a Check-in STEP, at the next sensible breakpoint — after a"
  echo "  capability lands, not mid-feature. Advice, not a gate ($DOCS_REL/METHOD.md §10 rule 7): it does"
  echo "  not replace the action above, and a scheduled check-in never blocks work."
fi
echo
echo "Check-in:"
echo "  $ci"
