#!/usr/bin/env bash
#
# Contract coverage for the prose documents that other files open, quote, or parse.
#
# Truncate METHOD.md, AGENTS.md, BOOTSTRAP-PROMPT.md or runbooks/check-in.md to one line each
# and every other test in tests/ still passes — nothing else in the suite reads a document's
# body. That matters more here than in a normal repo, because in this one the documents ARE
# part of the machinery: several state, in words, a rule that a script enforces in code
# somewhere else. When those two drift the script keeps working and the document quietly
# starts lying — METHOD.md can teach a STEP status the doctor hard-FAILs, or name a check-in
# window status.sh does not compute, and nothing anywhere notices.
#
# So this file pins only the parts of a document that have an identified reader: a script that
# greps for the exact string, a sibling document that quotes it, or a template a generated
# project is checked against. Wherever possible the expected value is DERIVED from the
# enforcing code rather than written down a second time, so the assertion tracks the enforcer
# instead of becoming another copy of the rule that can drift on its own. Every derived list is
# checked for being non-empty before it is used. That floor catches an extraction that stops
# matching outright; it does not catch one that stops matching some of what it used to, so an
# extraction pattern here is worth reading as carefully as the assertion it feeds.
#
# There is deliberately no line-count floor: a document full of the wrong words passes one.
#
# This runs against the template repo, not a generated project: check.sh validates a project's
# own docs, while this guards the documents Throughstone ships.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$ROOT/Code/{{PROJECT}}-docs"

METHOD="$DOCS/METHOD.md"
AGENTS="$DOCS/AGENTS.md"
BOOT="$DOCS/BOOTSTRAP-PROMPT.md"
ONBOARD="$DOCS/ONBOARDING.md"
CHECKIN="$DOCS/runbooks/check-in.md"
CHECK_SH="$DOCS/scripts/check.sh"
STATUS_SH="$DOCS/scripts/status.sh"
SETUP_SH="$DOCS/scripts/setup-workspace.sh"
DOCTOR_SH="$DOCS/scripts/doctor.sh"
OVERVIEW_TPL="$DOCS/templates/overview-template.md"
ARCH_TPL="$DOCS/templates/architecture-doc-template.md"
SESSIONS="$DOCS/templates/architecture-sessions"

fail() { echo "FAIL: $*" >&2; exit 1; }

shopt -s nullglob

for f in "$METHOD" "$AGENTS" "$BOOT" "$ONBOARD" "$CHECKIN" "$CHECK_SH" "$STATUS_SH" \
         "$SETUP_SH" "$DOCTOR_SH" "$OVERVIEW_TPL" "$ARCH_TPL" "$ROOT/prompts/README.md" \
         "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$DOCS/templates/planning-session.md"; do
  [ -f "$f" ] || fail "expected file is missing: ${f#$ROOT/}"
done

# These documents hard-wrap, so a sentence one file quotes out of another routinely straddles a
# newline and a plain grep for it finds nothing. Compare on whitespace-collapsed text instead —
# the same normalization session-template-contract.sh uses on the session templates.
#
# Note the shape of every negative test below: "if grep ...; then fail; fi", never a bare
# "! grep". Under set -e a bare "!" statement mid-script is inert — nothing reads its status —
# so an assertion written that way can never fail. (There is no backtick anywhere in this file
# on purpose: one inside a comment inside a $(...) is enough to break the whole script.)
# Every extraction below ends in "|| true" for one reason: with set -e and pipefail, a grep that
# matches nothing fails its pipeline and aborts the script mid-assignment, exiting 1 with no
# message at all. The explicit non-empty check that follows each extraction is what reports it.
flat() { tr -s ' \t\n' ' ' < "$1"; }
contains() {  # contains FILE STRING — substring test on the flattened file
  case "$(flat "$1")" in *"$2"*) return 0 ;; *) return 1 ;; esac
}
section() {   # section FILE N — the body of "## N. …" up to the next "## "
  awk -v n="$2" '$0 ~ "^## " n "\\. " { f = 1; print; next } /^## /{ f = 0 } f' "$1"
}

# --- 1. Section citations resolve --------------------------------------------
# Both the helpers and the documents send a reader to a numbered section by number —
# check.sh prints "See Code/<project>-docs/METHOD.md §1." under a finding, AGENTS.md points at
# METHOD.md §10 for the resolver, METHOD.md §7 points at ONBOARDING.md §6. Nothing resolves
# those: links.sh checks Markdown link targets, and a "§7" in running prose is not a link. So
# renumbering a section leaves every citation of it pointing somewhere else, silently.
CITERS=(
  "$CHECK_SH" "$STATUS_SH" "$SETUP_SH"
  "$AGENTS" "$BOOT" "$ONBOARD" "$CHECKIN" "$METHOD"
)
cites="$(
  for f in "${CITERS[@]}"; do
    # A citation such as "…/METHOD.md §10" is reduced to "METHOD.md 10". The path prefix
    # varies (a shell variable in the scripts, the generated path in the docs), so the
    # basename is what gets resolved below.
    flat "$f" | grep -oE '[A-Za-z0-9_/{}.-]+\.md.{0,3}§[0-9]+' \
      | sed -E 's|.*/||; s|\.md.*§|.md |' || true
  done | sort -u
)"
# A global floor only: some of the files above legitimately carry no section citation today,
# so requiring one per file would be wrong. What it catches is the extraction breaking outright.
[ -n "$cites" ] || fail "found no '<doc>.md §N' citations at all — this check has stopped reading anything"
case "$cites" in *"METHOD.md "*) : ;; *) fail "no METHOD.md section citation found; check.sh, status.sh and AGENTS.md all carry several, so the extraction above is broken" ;; esac

cited_docs=""
while read -r doc sec; do
  [ -n "${doc:-}" ] || continue
  hits="$(find "$DOCS" -name "$doc" -type f)"
  case "$(printf '%s\n' "$hits" | grep -c .)" in
    1) : ;;
    *) fail "citation '$doc §$sec' names a basename that is not unique under the docs hub; make the citation specific or narrow this check" ;;
  esac
  grep -qE "^## $sec\. " "$hits" || fail "$doc has no '## $sec.' section, but it is cited as '$doc §$sec' — renumbering a section silently redirects every reference to it"
  case " $cited_docs " in *" $doc "*) : ;; *) cited_docs="$cited_docs $doc" ;; esac
done <<< "$cites"

# Every cited document's numbered sections must run 1..N with nothing missing or out of order.
# The citations above only prove the numbers used still exist; this catches the reorder that
# keeps them all present but moves the content out from under them.
for doc in $cited_docs; do
  file="$(find "$DOCS" -name "$doc" -type f)"
  nums="$(grep -oE '^## [0-9]+\. ' "$file" | grep -oE '[0-9]+' || true)"
  [ -n "$nums" ] || fail "$doc is cited by section number but has no '## N.' headings left"
  i=1
  for n in $nums; do
    [ "$n" -eq "$i" ] || fail "$doc numbered sections are not 1..N in order (found §$n where §$i was expected)"
    i=$((i + 1))
  done
done

# --- 2. BOOTSTRAP-PROMPT.md's stages ------------------------------------------
# AGENTS.md, METHOD.md and all 17 session templates send the agent to a stage of the kickoff
# BY NUMBER — "ask the two local-profile questions from BOOTSTRAP-PROMPT.md Stage 0". A stage
# that is renamed, renumbered or dropped makes every one of those instructions a dead end.
stages="$(
  for f in "$AGENTS" "$METHOD" "$CHECKIN" "$SESSIONS"/*.md "$DOCS/templates/planning-session.md"; do
    [ -f "$f" ] || continue
    flat "$f" | grep -oE 'BOOTSTRAP-PROMPT\.md.{0,3}Stage [0-9]+' | grep -oE '[0-9]+$' || true
  done | sort -un
)"
[ -n "$stages" ] || fail "no 'BOOTSTRAP-PROMPT.md Stage N' citations found — the session templates all carry one, so this check has stopped reading anything"
for s in $stages; do
  grep -qE "^### Stage $s([^0-9]|$)" "$BOOT" || fail "BOOTSTRAP-PROMPT.md has no 'Stage $s' heading, but other documents send the agent there by that number"
done

# --- 3. The STEP status vocabulary --------------------------------------------
# METHOD.md §1 teaches the status vocabulary; check.sh check 3 enforces it in awk. Nothing has
# ever read both, so a rename on either side leaves the other teaching a status the doctor
# rejects. Derive the set the doctor actually accepts and require §1 to name each one.
#
# This is one direction, not both: it catches a status check.sh accepts that §1 stopped naming.
# The other direction — §1 growing a sixth status the doctor rejects — is covered only as far as
# the closing sentence goes, since an editor who adds one and updates "These five" to "These six"
# trips the literal below. An editor who adds one and leaves the sentence alone does not, and
# pinning that would mean parsing statuses out of running prose.
statuses="$(grep -oE 'sc != "[^"]*"' "$CHECK_SH" | sed 's/.*"\(.*\)"/\1/' || true)"
[ -n "$statuses" ] || fail "could not read the accepted status values out of check.sh check 3"
m1="$(section "$METHOD" 1)"
[ -n "$m1" ] || fail "METHOD.md has no '## 1.' section — the STEP status vocabulary is taught there"
step_states=0
while IFS= read -r st; do
  [ -n "$st" ] || continue
  if [ "$st" = "N/A" ]; then
    # N/A is the one status check.sh accepts on a substep row only (check.sh check 3 rejects it
    # on a STEP row), so METHOD.md has to introduce it as a substep status, not a STEP state.
    grep -qE 'substep.*N/A|N/A.*substep' "$METHOD" || fail "check.sh accepts 'N/A' on substep rows but METHOD.md never names it as a substep status"
    continue
  fi
  step_states=$((step_states + 1))
  case "$m1" in
    *"$st"*) : ;;
    *) fail "check.sh check 3 accepts the STEP status \"$st\" but METHOD.md §1 does not teach it — a project following METHOD.md would write a status the doctor rejects (or vice versa)" ;;
  esac
done <<< "$statuses"
[ "$step_states" -eq 5 ] || fail "check.sh accepts $step_states STEP statuses, but METHOD.md §1 says \"These five are the only STEP states.\""
case "$m1" in
  *"These five are the only STEP states."*) : ;;
  *) fail "METHOD.md §1 no longer closes the status list with \"These five are the only STEP states.\" — the sentence is what makes the vocabulary exhaustive rather than illustrative" ;;
esac

# --- 4. The kickoff gate marker -----------------------------------------------
# status.sh greps overview.md for one literal string and treats its absence as "kickoff already
# happened". Three documents have to agree with that literal: the template a new project's
# overview.md is copied from (or the gate never arms), AGENTS.md (which decides kickoff vs.
# resume from it), and BOOTSTRAP-PROMPT.md (which flips it at the end of the kickoff).
gate="$(awk -F"'" '/grep -q .PROJECT-STATUS/ { print $2 }' "$STATUS_SH")"
[ -n "$gate" ] || fail "could not read the PROJECT-STATUS marker status.sh gates on"
gate_name="${gate%%:*}"
contains "$OVERVIEW_TPL" "<!-- $gate -->" || fail "templates/overview-template.md does not carry '<!-- $gate -->' — a project created from it would skip the kickoff entirely, because status.sh reads the gate as already cleared"
contains "$AGENTS" "$gate_name" || fail "AGENTS.md no longer names the $gate_name marker it decides kickoff-vs-resume from"
contains "$BOOT" "<!-- $gate -->" || fail "BOOTSTRAP-PROMPT.md no longer names '<!-- $gate -->' as the line the kickoff flips"
# The value the kickoff writes has no reader in code — status.sh only tests for the gate value
# above — so the only thing that keeps it honest is that both documents name the same one.
for f in "$AGENTS" "$BOOT"; do
  contains "$f" "kickoff-complete" || fail "$(basename "$f") no longer names 'kickoff-complete', the value the kickoff writes over $gate_name; if the two documents disagree the gate is flipped to something AGENTS.md does not recognize"
done

# --- 5. The check-in cadence numbers ------------------------------------------
# METHOD.md §5 states the cadence window in words and in numbers. status.sh computes it. The
# sentence has to be arithmetically true of the script, or an operator reads one window and the
# helper prints another.
cad_default="$(sed -n 's/^cadence=\([0-9][0-9]*\).*/\1/p' "$STATUS_SH" | head -1)"
cad_before="$(sed -n 's/^due=.*cadence - \([0-9][0-9]*\).*/\1/p' "$STATUS_SH" | head -1)"
cad_after="$(sed -n 's/^over=.*cadence + \([0-9][0-9]*\).*/\1/p' "$STATUS_SH" | head -1)"
[ -n "$cad_default" ] && [ -n "$cad_before" ] && [ -n "$cad_after" ] \
  || fail "could not read the cadence default and window offsets out of status.sh"
cad_sentence="so the default $cad_default gives a heads-up at $((cad_default - cad_before)) and overdue at $((cad_default + cad_after))"
contains "$METHOD" "$cad_sentence" || fail "METHOD.md §5 no longer states the window status.sh computes; from status.sh the sentence must read \"$cad_sentence\""

# The cadence marker itself: the seeded overview must carry a value status.sh's own extraction
# regex can read, or the project silently falls back to the default it thinks it overrode.
cad_re="$(awk -F"'" '/grep -oE .CHECK-IN-CADENCE/ { print $2 }' "$STATUS_SH")"
[ -n "$cad_re" ] || fail "could not read status.sh's CHECK-IN-CADENCE pattern"
cad_line="$(grep -F 'CHECK-IN-CADENCE:' "$OVERVIEW_TPL" | head -1 || true)"
[ -n "$cad_line" ] || fail "templates/overview-template.md no longer seeds a CHECK-IN-CADENCE marker"
printf '%s\n' "$cad_line" | grep -qE "$cad_re" || fail "the CHECK-IN-CADENCE marker seeded in templates/overview-template.md is not one status.sh can read: $cad_line"

# --- 6. Index-row titles the resolver keys on ---------------------------------
# Two next-action behaviours are triggered by how a human titles a row in prompts/STEP-index.md:
# status.sh measures the check-in cadence from the last Done STEP whose Title begins "Check-in",
# and prioritizes a follow-up whose Title begins "Conditional session:". Both are anchored
# regexes. Every document that tells an author how to title the row must give a title those
# regexes actually match — the documents are the only specification an author ever sees.
ci_re="$(awk -F"'" '/grep -qiE/ && /check-in/ { print $4 }' "$STATUS_SH" | head -1)"
cond_re="$(awk -F"'" '/grep -qiE/ && /conditional session:/ { print $4 }' "$STATUS_SH" | head -1)"
[ -n "$ci_re" ] && [ -n "$cond_re" ] || fail "could not read status.sh's Title-matching patterns"

CI_TITLE='Check-in: phase 1'          # the example METHOD.md §5 and check-in.md both print
COND_TITLE='Conditional session: '    # the prefix check-in.md tells the author to use
printf '%s\n' "$CI_TITLE" | grep -qiE "$ci_re" || fail "the check-in row title the documents give as an example (\"$CI_TITLE\") does not match status.sh's cadence pattern, so a project following them would have no measurable check-in"
printf '%s\n' "${COND_TITLE}identity-auth" | grep -qiE "$cond_re" || fail "the conditional follow-up title the documents prescribe (\"$COND_TITLE…\") does not match status.sh's pattern, so such a STEP would never be prioritized"
# The anchor is the whole point of the check-in pattern: check-in.md's own Carry-forward step
# produces rows *named after* the check-in that found them, and an unanchored match read those
# as check-ins and reset the clock. Keep a title that merely mentions one from matching.
if printf '%s\n' 'Bug found by the check-in' | grep -qiE "$ci_re"; then
  fail "status.sh's check-in Title pattern is no longer anchored — a STEP merely named after a check-in now resets the cadence clock"
fi

for f in "$METHOD" "$CHECKIN" "$DOCS/templates/planning-session.md" "$ROOT/prompts/README.md"; do
  contains "$f" "$CI_TITLE" || fail "${f#$ROOT/} no longer shows '$CI_TITLE' as the check-in row title; it is one of the documents an author writes that row from"
done
for f in "$METHOD" "$CHECKIN" "$AGENTS"; do
  contains "$f" "$COND_TITLE" || fail "${f#$ROOT/} no longer names the '$COND_TITLE<topic>' row title the next-action resolver prioritizes on"
done

# --- 7. Conditional sessions are invoked by name ------------------------------
# status.sh prints a literal phrase for the user to type ("run the identity-auth session").
# AGENTS.md and METHOD.md §10 are what teach an agent to recognize that phrase and open the
# matching template. If the wording drifts, the helper's advice invokes nothing.
invocations="$(grep -oE 'cond_example="run the [a-z-]+ session"' "$STATUS_SH" | sed 's/^cond_example="//; s/"$//' || true)"
[ -n "$invocations" ] || fail "could not read the by-name conditional invocations status.sh prints"
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  contains "$AGENTS" "$inv" || fail "status.sh tells the user to say \"$inv\" but AGENTS.md does not teach that invocation"
  contains "$METHOD" "$inv" || fail "status.sh tells the user to say \"$inv\" but METHOD.md §10 does not list that invocation"
done <<< "$invocations"

# And the other direction: a conditional template is reached by name, never by number, so a
# template AGENTS.md does not name is one no agent can be asked to run.
conditionals=("$SESSIONS"/conditional-*.md)
[ ${#conditionals[@]} -gt 0 ] || fail "no conditional-*.md session templates found under ${SESSIONS#$ROOT/}"
for f in "${conditionals[@]}"; do
  b="$(basename "$f")"
  contains "$AGENTS" "$b" || fail "AGENTS.md does not name $b — conditional sessions are invoked by name, so a template it never names cannot be reached"
done

# --- 8. The helper surface the documents tell people to run -------------------
# doctor.sh dispatches a fixed set of commands. AGENTS.md and ONBOARDING.md are where a human or
# agent learns they exist; doctor-dispatcher.sh proves the dispatcher's own help text can be
# deleted without a test noticing, so these two documents are the surface's only description.
cmds="$(grep -oE '^ +run_helper [a-z][a-z0-9-]*' "$DOCTOR_SH" | awk '{ print $2 }' | sort -u || true)"
[ -n "$cmds" ] || fail "could not read the command surface out of scripts/doctor.sh"
for c in $cmds; do
  contains "$AGENTS" "./doctor.sh $c" || fail "AGENTS.md does not document './doctor.sh $c', a command the dispatcher implements"
  contains "$ONBOARD" "./doctor.sh $c" || fail "ONBOARDING.md §4 does not document './doctor.sh $c', a command the dispatcher implements"
done

# --- 9. What setup-workspace.sh leaves at the workspace root ------------------
# ONBOARDING.md §2 tells a new contributor to verify a specific list of files after running the
# helper. That list is the only check anyone performs on the helper's first step, so it has to
# be the files the helper actually writes.
rootfiles="$(
  { sed -n 's/^for name in \(.*\); do$/\1/p' "$SETUP_SH" | tr ' ' '\n'
    grep -oE 'cat > "\$ROOT/[^"$]+"' "$SETUP_SH" | sed 's|.*ROOT/||; s|"$||' || true
  } | sed '/^$/d' | sort -u
)"
[ -n "$rootfiles" ] || fail "could not read the root files setup-workspace.sh writes"
onb2="$(section "$ONBOARD" 2)"
[ -n "$onb2" ] || fail "ONBOARDING.md has no '## 2.' section — the workspace setup steps live there"
# Compared as a set, in both directions: a file the helper writes and the list omits is an
# unverified step, and a file the list names and the helper does not write is an instruction that
# fails for every contributor. Set equality also means neither extraction can quietly stop
# matching and leave the other half checking nothing.
onb_list="$(printf '%s\n' "$onb2" | awk '/^- / { gsub(/^- |[^A-Za-z0-9._\/-]/, ""); if (length($0)) print }' | sort -u)"
[ -n "$onb_list" ] || fail "ONBOARDING.md §2 no longer lists any files to verify after setup-workspace.sh runs"
if [ "$onb_list" != "$rootfiles" ]; then
  fail "ONBOARDING.md §2 tells the contributor to verify [$(printf '%s' "$onb_list" | tr '\n' ' ')] but setup-workspace.sh writes [$(printf '%s' "$rootfiles" | tr '\n' ' ')] at the workspace root"
fi

# --- 10. The architecture-doc header contract ---------------------------------
# check.sh check 4 FAILs any architecture/NN-*.md missing these fields — but it runs against a
# generated project, and the scaffold has no architecture docs, so nothing here checks that the
# template those docs are written from still carries them. Lose a field in the template and
# every project built afterwards fails its own doctor on its own first architecture doc.
fields="$(awk -F"'" '/^# --- 4\./{ f = 1 } /^# --- 5\./{ f = 0 } f && /grep -q/ { print $2 }' "$CHECK_SH")"
[ -n "$fields" ] || fail "could not read the required architecture-doc fields out of check.sh check 4"
m6="$(section "$METHOD" 6)"
[ -n "$m6" ] || fail "METHOD.md has no '## 6.' section — the architecture-doc header fields are taught there"
while IFS= read -r fld; do
  [ -n "$fld" ] || continue
  grep -qiF "$fld" "$ARCH_TPL" || fail "templates/architecture-doc-template.md is missing '$fld', which check.sh check 4 requires of every architecture doc"
  bare="${fld//\*/}"
  case "$(printf '%s' "$m6" | tr '[:upper:]' '[:lower:]')" in
    *"$(printf '%s' "$bare" | tr '[:upper:]' '[:lower:]')"*) : ;;
    *) fail "METHOD.md §6 does not teach the '$bare' header field that check.sh check 4 requires" ;;
  esac
done <<< "$fields"

# runbooks/check-in.md branches its sweeps on two of §6's Status rungs and on the Coverage
# field — it skips a Deprecated doc and only treats a Current one as covering an input. Rename
# a rung in METHOD.md and those branches match nothing, silently sweeping the wrong set.
for rung in Current Deprecated; do
  case "$m6" in
    *"**$rung**"*) : ;;
    *) fail "METHOD.md §6 no longer teaches the '$rung' Status rung, which runbooks/check-in.md branches its sweeps on" ;;
  esac
  contains "$CHECKIN" "$rung" || fail "runbooks/check-in.md no longer names the '$rung' Status rung it excludes or requires"
done
case "$m6" in *"Coverage:"*) : ;; *) fail "METHOD.md §6 no longer teaches the 'Coverage:' field the check-in's deferred-coverage sweep reads" ;; esac
contains "$CHECKIN" "Coverage:" || fail "runbooks/check-in.md no longer reads the 'Coverage:' field its deferred-coverage sweep is built on"

# --- 11. The section the root pointers send every agent to --------------------
# The root AGENTS.md/CLAUDE.md — and setup-workspace.sh, which regenerates them on every new
# machine — promise that the canonical AGENTS.md "opens with" a section of this exact name, and
# status.sh and METHOD.md §10 both cite it. Rename or move it and the first instruction every
# agent receives points at nothing.
first_h2="$(grep -m1 -E '^## ' "$AGENTS" | sed 's/^## //' || true)"
[ "$first_h2" = "First action — kickoff or resume?" ] || fail "the docs hub AGENTS.md no longer opens with the 'First action — kickoff or resume?' section (first section is now: $first_h2)"
for p in "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md"; do
  contains "$p" "\"$first_h2\"" || fail "the workspace-root ${p#$ROOT/} quotes a different section name than the one the docs hub AGENTS.md actually opens with"
done
contains "$METHOD" '"First action"' || fail "METHOD.md §10 no longer points a resuming agent at AGENTS.md's \"First action\""

# --- 12. The seeded overview does not trip the doctor it ships with -----------
# check.sh check 6 WARNs on the legacy personal-preference sections that used to live in
# overview.md. The template a project's overview.md is copied from must not carry them, or every
# new project warns about its own seed on its first doctor run.
legacy_re="$(awk -F"'" '/legacy_profile_fields=/ { print $2 }' "$CHECK_SH")"
[ -n "$legacy_re" ] || fail "could not read check.sh check 6's legacy-profile pattern"
if grep -qE "$legacy_re" "$OVERVIEW_TPL"; then
  fail "templates/overview-template.md carries a legacy personal-preference section that check.sh check 6 warns about"
fi

echo "document contract ($(printf '%s\n' "$cites" | grep -c .) section citations, ${#conditionals[@]} conditional templates): PASS"
