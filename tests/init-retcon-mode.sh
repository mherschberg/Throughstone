#!/usr/bin/env bash
#
# Regression coverage for init.sh's new-vs-existing fork (retcon adoption).
#
# Asserts:
#   - Existing mode sets PROJECT-STATUS: retcon, seeds the stub STEP-1 PLAN at the greenfield
#     in-flight path, keeps the STEP index greenfield-identical, and leaves check.sh clean; a
#     fresh agent is routed to RETCON-PROMPT.md (status.sh).
#   - New mode (explicit and default) is unchanged: PROJECT-STATUS: not-started, no stub PLAN,
#     the greenfield kickoff message.
#   - An invalid --mode fails before the destructive bootstrap boundary.
#   - Marker-loss recovery: with PROJECT-STATUS stripped mid-adoption, the two disk signals the
#     AGENTS.md "First action" fallback keys on (an in-flight stub STEP-1 PLAN over a still-bare
#     STEP-index seed) still hold; a marker-stripped greenfield presents neither, so it cannot be
#     misrecovered as a retcon.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-retcon-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree
# changes so this test covers uncommitted bootstrap edits (same helper as the sibling tests).
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

# assert_file_contains FILE NEEDLE — fixed-string presence with a readable failure.
assert_file_contains() {
  grep -Fq -- "$2" "$1" || { echo "FAIL: '$2' not found in $1" >&2; return 1; }
}

# The superseded spelling must not come back alongside the new one, which is how a value ends up
# written two ways and every positive assertion still passes. The needle has to be as specific as
# a present-assertion one, or it matches unrelated prose.
assert_file_absent() {
  if grep -Fq -- "$2" "$1"; then
    echo "FAIL: '$2' still present in $1" >&2
    return 1
  fi
}

# run_existing_case NAME LAYOUT — adopt an existing codebase in the given layout and assert the
# retcon front-door state.
run_existing_case() {
  local name="$1" layout="$2"
  local work="$TMP_ROOT/$name"
  local docs="$work/Code/$name-docs"
  local plan="$work/Upcoming Prompts/$name-STEP-1-PLAN.md"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=existing \
      --slug="$name" \
      --desc="Adopt an existing codebase" \
      --license=private \
      --layout="$layout" \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  # 1. Status marker flipped to retcon.
  assert_file_contains "$docs/overview.md" "PROJECT-STATUS: retcon"
  ! grep -Fq "PROJECT-STATUS: not-started" "$docs/overview.md"

  # 2. Stub STEP-1 PLAN seeded at the greenfield in-flight path, fully resolved.
  [ -f "$plan" ] || { echo "FAIL: $name did not seed $plan" >&2; return 1; }
  assert_file_contains "$plan" "Retcon baseline"
  assert_file_contains "$plan" "| inv-1 |"          # the lowest open inventory substep
  assert_file_contains "$plan" "| inv-5 |"
  if grep -Eq '\{\{(PROJECT|DATE)\}\}' "$plan"; then
    echo "FAIL: $name stub PLAN has unresolved placeholders" >&2
    grep -nE '\{\{(PROJECT|DATE)\}\}' "$plan" >&2
    return 1
  fi
  grep -Eq '\*\*Date:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}' "$plan" \
    || { echo "FAIL: $name stub PLAN date not stamped" >&2; return 1; }

  # 2b. Pre-answer-sheet scratch folder scaffolded (a home for Stage-3 sheets + a marker-loss signal).
  [ -d "$work/Upcoming Prompts/retcon" ] \
    || { echo "FAIL: $name did not scaffold Upcoming Prompts/retcon/" >&2; return 1; }
  assert_file_contains "$work/Upcoming Prompts/retcon/README.md" "pre-answer sheet"

  # 3. STEP index stays byte-identical to the greenfield seed (slug-substituted).
  diff <(sed "s/{{PROJECT}}/$name/g" "$docs/templates/step-index-seed.md") \
       "$work/prompts/STEP-index.md" >/dev/null \
    || { echo "FAIL: $name STEP-index diverged from the greenfield seed" >&2; return 1; }

  # 4. check.sh is clean (warnings allowed; a FAIL exits non-zero).
  if ! bash "$docs/scripts/check.sh" >"$TMP_ROOT/$name-check.out" 2>&1; then
    echo "FAIL: $name check.sh reported a hard failure" >&2
    cat "$TMP_ROOT/$name-check.out" >&2
    return 1
  fi

  # 5. status.sh routes a fresh agent to RETCON-PROMPT.md rather than resolving the index.
  bash "$docs/scripts/status.sh" >"$TMP_ROOT/$name-status.out" 2>&1
  assert_file_contains "$TMP_ROOT/$name-status.out" "marker: retcon"
  assert_file_contains "$TMP_ROOT/$name-status.out" "RETCON-PROMPT.md"

  # 5b. The routing target itself ships, substituted (it is what status.sh/AGENTS.md point at).
  [ -f "$docs/RETCON-PROMPT.md" ] || { echo "FAIL: $name missing RETCON-PROMPT.md" >&2; return 1; }
  if grep -Eq '\{\{PROJECT\}\}' "$docs/RETCON-PROMPT.md"; then
    echo "FAIL: $name RETCON-PROMPT.md has unresolved {{PROJECT}} placeholder" >&2
    return 1
  fi
  assert_file_contains "$docs/RETCON-PROMPT.md" "Stage 1 — Intake"
  assert_file_contains "$docs/RETCON-PROMPT.md" "Upgrade this PLAN by addition"
  assert_file_contains "$docs/RETCON-PROMPT.md" "Stage 3 — Harvest→confirm"
  # The harvest writes architecture docs from the shared template, so they carry Version / Status /
  # Version Log and the landed baseline passes its own check.sh check 4.
  assert_file_contains "$docs/RETCON-PROMPT.md" "templates/architecture-doc-template.md"
  # The work list is addressed by the one heading every session template now uses (1.7.2 contract).
  assert_file_contains "$docs/RETCON-PROMPT.md" "## Decisions to make (in order)"
  # The STEP index is held at its seed for the whole adoption: session templates ask for several
  # different edits to it, and all of them are redirected to the PLAN. Landing reconciles the index.
  assert_file_contains "$docs/RETCON-PROMPT.md" "leave \`prompts/STEP-index.md\` alone entirely"
  # Adoption skips the kickoff interview, so a session fills the project brief instead — otherwise
  # the project lands with overview.md still the blank template every later session reads first.
  assert_file_contains "$docs/RETCON-PROMPT.md" "also fills in \`overview.md\`"
  # A lifted doc and an included conditional's output doc draw numbers from the same pool above the
  # core block, but a conditional's is assigned in the PLAN long before any file carries it — so
  # "free" has to mean unclaimed, not merely absent from disk.
  assert_file_contains "$docs/RETCON-PROMPT.md" "Free means unused on disk"
  # Every doc kind the recon map classifies needs a destination; a real decision record keeps its
  # own genre instead of being synthesized into an architecture doc.
  assert_file_contains "$docs/RETCON-PROMPT.md" "adopted into \`adr/\`, not synthesized away"
  # A breadth scan finds things that shouldn't be adopted, so the confirm gate settles scope and the
  # PLAN upgrade projects only the adopted rows into work.
  assert_file_contains "$docs/RETCON-PROMPT.md" "Complete is not the same as in scope"
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" "excluded — <reason>"
  # The UI session's option-page procedure is for deciding a design system, not describing one that
  # already ships.
  assert_file_contains "$docs/RETCON-PROMPT.md" "documents the design system that already exists"
  # Every adopted repo is registered in place, so the method records its licensing and never sets
  # it. Losing either half is silent: the prohibition is the only thing standing between the
  # README stamp comment's license instruction and someone's production repo, and the recon-map
  # column is the record that makes "record it" an actual place rather than a sentiment.
  assert_file_contains "$docs/RETCON-PROMPT.md" "Never license an adopted repo"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "\`scripts/apply-project-license.sh\` against any of these repos"
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "Licensing (as found)"
  # Whether a repo explains its place in the system is a fact about the repo, recorded once during
  # the scan like its licensing — not rediscovered per repo at the moment of writing into it. The
  # column is what lets inv-4 say the shape out loud and the substeps arrive expected.
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "Docs (as found)"
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "role-stated / README, no role / none"
  assert_file_contains "$docs/RETCON-PROMPT.md" "Say what the docs column adds up to"
  # The line is an observation, never a gate. A blanket yes collected before any text exists would
  # be consent to writes nobody has seen — the opposite of what the per-repo proposal is for — so
  # both halves are pinned: say the shape, and do not turn it into an approval.
  assert_file_contains "$docs/RETCON-PROMPT.md" "**Do not turn it"
  assert_file_contains "$docs/RETCON-PROMPT.md" "do not collect a blanket yes"
  # The README outcome has a durable home. Adoption is where this bites hardest: the same proposal
  # goes to the same people once per repo, so a decline may cover all of them — and the instruction
  # to record that named nowhere to record it, leaving the answer in the session that produced it.
  # A check-in months later then could not tell a refusal from a repo nobody had asked.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "**Record how it went in that repo's row, as its \`readme:\` value**"
  # The standing decline is one edit per row, made when it is given.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "documenting themselves — which means writing \`readme: declined\` on every one of their rows now,"
  # A README that already says the repo's place needs no proposal, under the same name the map uses.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "missing, so propose nothing — the map recorded that as \`role-stated\` and the row records it the"
  # Two records of one subject need a stated precedence, or they become two answers that disagree
  # with nothing saying which wins. The map is the frozen finding; the row is the living outcome.
  # Pinned on BOTH sides: a rule stated only where it is defined goes stale where it is read.
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "**This column is the finding; \`registries/repos.yml\`'s \`readme:\` field is the outcome.**"
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "to correct, and this map is left alone**"
  assert_file_contains "$docs/registries/repos.yml" \
    "# That column is the FINDING and is frozen; this field is the OUTCOME and is living, so the two are"
  # The column value and the field value naming the same outcome are spelled identically, so moving
  # between the two files does not read as a typo. The old spaced form must not come back.
  assert_file_absent "$docs/templates/reports/recon-map-report-template.md" "\`role stated\`"

  # A decline carries to the remaining repos; a yes never does.
  assert_file_contains "$docs/RETCON-PROMPT.md" "**And a no can stand for the rest.**"
  assert_file_contains "$docs/RETCON-PROMPT.md" "a yes is never carried"
  # Remotes and visibility. The file said nothing at all about either — it had zero occurrences of
  # "remote" — while adoption is the exact circumstance where the mistake is easiest and worst: a
  # stranger's private codebase, many repos in flight, and no undo once one is published. Both the
  # never-touch rule and the scope of a go-ahead are pinned; a go-ahead that silently covered
  # siblings would be the whole failure, dressed as permission.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "**Never touch an adopted repo's remote, and never change its visibility.**"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "change no repository's visibility, in either direction, for any reason"
  assert_file_contains "$docs/RETCON-PROMPT.md" "never a standing one, never extended to a"
  # What happens after the yes. The prompt told an agent to write into a running system's repo and
  # said nothing about branch, commit, or push — so the obvious continuation was a commit on
  # whatever branch was out (main, on an adopted repo) and a push to their remote. The method now
  # stops at a local commit on a branch they can inspect, amend, or delete.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "**On a yes, commit it on a branch and stop.**"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "**Never push, open a pull request, or merge**"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "which would sweep up whatever they had in progress"
  # The commit covers everything the method wrote, not just the file that was proposed. An accepted
  # addition leaves the README plus the two files --notice-only places, and only the README is ever
  # proposed — so a commit scoped to the proposal handed the owners a branch carrying the section
  # without the notice that explains it, and left the other two untracked in their working tree at
  # the point the agent had been told to stop.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "commit every file the method just wrote into that repo"
  # Which means the notice mode runs BEFORE the commit. Its paragraph is placed ahead of the
  # landing paragraph so the resolver reads in the order it is meant to execute; an agent working
  # top-to-bottom that hits the commit first has already stopped by the time it reaches the notice.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "Run it **now**, before the commit below, so those two files go in with the README change; run"
  local notice_line landing_line
  notice_line="$(grep -n -F -- "**Place the Throughstone notice only if something Throughstone-authored landed.**" \
    "$docs/RETCON-PROMPT.md" | head -1 | cut -d: -f1)"
  landing_line="$(grep -n -F -- "**On a yes, commit it on a branch and stop.**" \
    "$docs/RETCON-PROMPT.md" | head -1 | cut -d: -f1)"
  [ -n "$notice_line" ] && [ -n "$landing_line" ] && [ "$notice_line" -lt "$landing_line" ] || {
    echo "FAIL: $name RETCON-PROMPT.md states the landing commit before the notice that rides on it" >&2
    echo "       notice at line ${notice_line:-none}, landing commit at line ${landing_line:-none}" >&2
    return 1
  }
  # An ARCHITECTURE.md at an adopted repo's root is a file appearing in somebody else's repository,
  # and the template comment suggesting one is inside the Overview section a README-less repo gets
  # written from. Adopted repos are exactly the ones with real internal complexity.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "complexity **that this method created**, and adoption creates none: these repos have the"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "docs hub's \`architecture/\`, never as a second new file at its root. Where a repo already has an"
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "Licensing is recorded as found, never set here"
  # A user who has just chosen the project's license should hear where their own repos don't match
  # it — once, at the checkpoint where they chose and the licensing column is in front of them.
  # Both halves are pinned because either one alone is a failure mode: without the telling, the
  # method silently knows something the user would want; without the bound, an agent re-raises it
  # at every repo and turns a one-line observation into pressure to relicense.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "say once where their own repos don't match"
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "recorded, not reconciled"
  assert_file_contains "$docs/RETCON-PROMPT.md" "do not re-raise it here"
  # The frozen map is the snapshot; the inventory row is the living copy. Both must be asked for,
  # and asked for as a copy — deriving the row separately is how two records start disagreeing.
  assert_file_contains "$docs/RETCON-PROMPT.md" "this row's \`license:\` field is"
  assert_file_contains "$docs/RETCON-PROMPT.md" "Copy it across as found"
  assert_file_contains "$docs/registries/repos.yml" "\`license:\` (per row) records"
  # An adopted repo's README is the user's most-read file and there is no helper that can refuse
  # an overwrite — it is one file write — so both halves are pinned: never stamp, and the bounded
  # thing that may be added instead, only with a yes.
  assert_file_contains "$docs/RETCON-PROMPT.md" \
    "Where a README already exists, augment it; never stamp over it"
  # ...and that the no-README case is not left to inference.
  assert_file_contains "$docs/RETCON-PROMPT.md" "offer to write one from the template"
  # Substituted, like every other {{PROJECT}} in the shipped file — asserting the raw placeholder
  # here would pass on a template that never got substituted.
  assert_file_contains "$docs/RETCON-PROMPT.md" "\`## Role in $name\` section"
  assert_file_contains "$docs/RETCON-PROMPT.md" "wait for a yes"
  # CI is the one thing adoption must never install: the shipped gate fails until configured, so
  # in a running system it either replaces the real gate or reddens every build.
  assert_file_contains "$docs/RETCON-PROMPT.md" "Never install CI into an adopted repo"
  # The notice follows the README decision rather than the repo: owed only if material landed, and
  # placeable only through the mode that writes no project LICENSE.
  assert_file_contains "$docs/RETCON-PROMPT.md" "\`scripts/apply-project-license.sh --notice-only <repo-path>\`"
  assert_file_contains "$docs/RETCON-PROMPT.md" "nothing Throughstone-authored is in the repo and"
  # The three places that tell a reader to record an in-place repo's licensing must name the field
  # that holds it. They are deliberately field-free on the 1.7.x line, where no such field exists,
  # so a later forward-merge can quietly reintroduce the vaguer wording here.
  assert_file_contains "$docs/METHOD.md" \
    "\`registries/repos.yml\` \`license:\` field (an identifier"
  assert_file_contains "$docs/AGENTS.md" "repo's \`registries/repos.yml\` \`license:\` field"
  assert_file_contains "$docs/templates/planning-session.md" \
    "\`registries/repos.yml\` \`license:\` field and move on"
  # The header states the field correctly; this is the comment at the point where a row is actually
  # written, and every adopted repo's row is written there. It used to say "a `license:` like the
  # rows above" — and the rows above carry the install-time posture, so an agent registering a
  # GPL repo was being shown MIT as the pattern. Both halves pinned: the instruction, and a
  # worked in-place example, since an example is what gets copied.
  assert_file_contains "$docs/registries/repos.yml" \
    "takes whatever that repo itself already says, copied as found"
  assert_file_contains "$docs/registries/repos.yml" "license: \"GPL-2.0 (COPYING)\""
  if grep -Fq "a \`license:\` like the rows above" "$docs/registries/repos.yml"; then
    echo "FAIL: $name still points an in-place repo's license: at the project posture" >&2
    return 1
  fi
  # The same comment must not claim every repo listed there is stamped from the README template.
  assert_file_contains "$docs/registries/repos.yml" "REGISTERED IN PLACE is listed"
  # The created-repo example beside it says "the posture, as on the rows above", so it has to BE
  # the posture — it carries {{PROJECT_LICENSE}}, which init.sh substitutes wherever it appears,
  # the seed rows included. That example is what an agent copies when it registers a repo, so a
  # literal identifier there would be copied into every row of a project that chose something
  # else. This case builds with --license=private, which is why a literal cannot pass by
  # coincidence: the example must read Proprietary, and MIT — the likeliest thing for someone to
  # type into an example — must not appear anywhere in the file.
  assert_file_contains "$docs/registries/repos.yml" "license: \"Proprietary\""
  if grep -Fq 'license: "MIT"' "$docs/registries/repos.yml"; then
    echo "FAIL: $name shows MIT in the repo inventory of a project that chose Proprietary" >&2
    return 1
  fi
  if grep -Fq '{{PROJECT_LICENSE}}' "$docs/registries/repos.yml"; then
    echo "FAIL: $name left the license placeholder unsubstituted in the repo inventory" >&2
    return 1
  fi
  # ...while the in-place example must NOT track the posture. Its whole job is to show a repo
  # carrying something else, so templating both examples would delete the contrast that makes the
  # rule legible.
  if ! grep -Fq 'license: "GPL-2.0 (COPYING)"' "$docs/registries/repos.yml"; then
    echo "FAIL: $name lost the in-place example that differs from the project posture" >&2
    return 1
  fi
  # Mono-repo + adoption is a real combination this test exercises (run_existing_case runs both
  # layouts). The file's mono note says its rows are "folders inside the single repo, not separate
  # repos yet" — true of what the method creates, false of every row an adoption writes, and this
  # inventory holds both kinds at once. Scoped now, and pinned because the note reads perfectly
  # sensible on its own and only goes wrong next to a registered-in-place row.
  assert_file_contains "$docs/registries/repos.yml" \
    "as its own repo, at its own \`location\`, and stays there"

  # 5b. The repo README template, in an ADOPTION-generated project.
  # `RETCON-PROMPT.md` states these rules for the resolver and is pinned above, but the template's
  # own comment is the file an agent has open while writing into someone's repo — it is what the
  # resolver, METHOD.md §7 and the planning session all point at by name. Every existing assertion
  # on that comment reads a project generated with the default mode, so on the path where these
  # rules decide what happens to a repo the method did not create, nothing checked that the file
  # shipped carrying them. That is not the same guarantee: the docs hub an adoption produces is
  # assembled by the same installer but selected for by a different flag, and the rules are base
  # text, so a forward merge is free to erode them here without failing a greenfield assertion.
  local readme_tpl="$docs/templates/repo-readme-template.md"
  # Stamp what the method creates; augment what it registers, keyed on whether a README exists.
  assert_file_contains "$readme_tpl" "STAMP this into a repo the method CREATES"
  assert_file_contains "$readme_tpl" "## Role in $name"
  # The no-README path writes the template minus Licensing — that section describes a created repo,
  # and adoption is precisely where a repo with no README gets one written from this file.
  assert_file_contains "$readme_tpl" "every section except **Licensing**"
  # CI is never installed into a repo the method did not create.
  assert_file_contains "$readme_tpl" "never install it — that repo has its own CI"
  # The notice is owed where Throughstone-authored material landed, and only there. Substituted,
  # so an unsubstituted template cannot satisfy it.
  assert_file_contains "$readme_tpl" \
    "Code/$name-docs/scripts/apply-project-license.sh --notice-only <this-repo-path>"
  assert_file_contains "$readme_tpl" "is in the repo and nothing is owed"

  # 6. The bootstrap hand-off explains adoption, not the greenfield interview.
  #    Key on a distinctive phrase, not the substring "retcon" (which may sit inside the slug).
  assert_file_contains "$TMP_ROOT/$name.out" "ADOPT your existing codebase"
  ! grep -Fq "interview you, propose a roadmap" "$TMP_ROOT/$name.out"

  # 7. Where the user's code stays is said on EVERY path into adoption. This run is the flag path
  #    (--mode=existing, non-interactive) — the one that used to print nothing, because the notice
  #    lived inside the interactive prompt's branch. The work-tree guard refuses running from
  #    inside their repo; only this says where the code is meant to stay instead.
  assert_file_contains "$TMP_ROOT/$name.out" "NOT from inside your existing repo"
  assert_file_contains "$TMP_ROOT/$name.out" "never rewrites or relocates them"
}

# run_existing_env_case — the same fork via the INIT_MODE env var instead of the flag.
run_existing_env_case() {
  local name="retcon-env"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    INIT_MODE=existing ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Adopt via env var" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  assert_file_contains "$work/Code/$name-docs/overview.md" "PROJECT-STATUS: retcon"
  [ -f "$work/Upcoming Prompts/$name-STEP-1-PLAN.md" ] \
    || { echo "FAIL: $name (env) did not seed the stub PLAN" >&2; return 1; }
}

# run_deferred_license_case — adoption does not ask the license question at install time, and
# greenfield still does. Asked here it would arrive before anybody has read the codebase, with
# nothing to answer it from, and it reads as "what is your code licensed under?" — which is not
# what it sets. Adoption leaves the posture Unset and the recon-map checkpoint asks it instead.
run_deferred_license_case() {
  local name="retcon-license-deferred" green="green-license-question"
  local work="$TMP_ROOT/$name" green_work="$TMP_ROOT/$green"
  local question="Is this project open source"

  # The only answer offered is the mode. Reaching the end without a license prompt is the point:
  # a stray prompt would consume no input and the run would fail or hang instead of completing.
  copy_template "$work"
  (
    cd "$work"
    printf '2\n' | ./init.sh \
      --slug="$name" \
      --desc="Adoption defers the license question" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  if grep -Fq "$question" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name asked the license question before reading the codebase" >&2
    return 1
  fi
  assert_file_contains "$TMP_ROOT/$name.out" "asked later, once the agent has read your repos"

  # Unset is a real value, not an empty file: helpers must tell "not chosen yet" from truncated.
  local posture="$work/Code/$name-docs/.throughstone/project-license"
  grep -Fxq "Unset" "$posture" || {
    echo "FAIL: $name did not leave the posture Unset: $(cat "$posture" 2>&1)" >&2
    return 1
  }
  # No license is chosen, so none is rendered — and the placeholder summary says so rather than
  # leaving a reader to infer a posture nobody selected.
  if [ -e "$work/Code/$name-docs/LICENSE" ]; then
    echo "FAIL: $name wrote a project LICENSE with no license chosen" >&2
    return 1
  fi
  assert_file_contains "$work/Code/$name-docs/LICENSING.md" "has not chosen its license yet"
  assert_file_contains "$work/Code/$name-docs/registries/repos.yml" 'license: "Unset"'
  assert_file_contains "$work/Code/$name-docs/overview.md" "PROJECT-STATUS: retcon"

  # The checkpoint that asks the question must name the helper that answers it.
  assert_file_contains "$work/Code/$name-docs/RETCON-PROMPT.md" \
    "Answer the project-license question here"
  assert_file_contains "$work/Code/$name-docs/RETCON-PROMPT.md" \
    "scripts/set-project-license.sh"

  # Greenfield creates every repo it licenses and has nothing to read first, so it still asks.
  copy_template "$green_work"
  (
    cd "$green_work"
    printf '1\n1\n1\nThroughstone Test\n' | ./init.sh \
      --slug="$green" \
      --desc="Greenfield license question" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$green.out" 2>&1

  assert_file_contains "$TMP_ROOT/$green.out" "$question"
  grep -Fxq "MIT" "$green_work/Code/$green-docs/.throughstone/project-license" || {
    echo "FAIL: $green did not record the license chosen at install time" >&2
    return 1
  }
  assert_file_contains "$green_work/Code/$green-docs/overview.md" "PROJECT-STATUS: not-started"
}

# run_set_project_license_case — the helper the checkpoint runs. It answers the question once:
# it renders the license, settles every file init.sh left deferred, and refuses to change an
# answer already given (relicensing is a deliberate act across repos already stamped, not a
# flag flip). apply-project-license.sh must also refuse to stamp a repo before the answer exists.
run_set_project_license_case() {
  local name="retcon-license-set"
  local work="$TMP_ROOT/$name" docs

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=existing \
      --slug="$name" \
      --desc="Answering the deferred license question" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1
  docs="$work/Code/$name-docs"

  # A repo created before the question is answered has no posture to inherit. The refusal must
  # name the unanswered question, not read as a corrupt file.
  mkdir -p "$work/early-repo"
  if "$docs/scripts/apply-project-license.sh" "$work/early-repo" >"$TMP_ROOT/$name.early" 2>&1; then
    echo "FAIL: $name stamped a repo before the project chose a license" >&2
    return 1
  fi
  assert_file_contains "$TMP_ROOT/$name.early" "has not chosen its license yet"
  if [ -e "$work/early-repo/LICENSE" ] || [ -e "$work/early-repo/LICENSING.md" ]; then
    echo "FAIL: $name wrote into the target it refused" >&2
    return 1
  fi

  # An open-source answer needs a holder for the copyright line; without one nothing is written.
  if "$docs/scripts/set-project-license.sh" mit >"$TMP_ROOT/$name.noholder" 2>&1; then
    echo "FAIL: $name rendered an open-source license with no copyright holder" >&2
    return 1
  fi
  grep -Fxq "Unset" "$docs/.throughstone/project-license" || {
    echo "FAIL: $name changed the posture on a rejected answer" >&2
    return 1
  }

  "$docs/scripts/set-project-license.sh" mit --holder "Acme Corp" >"$TMP_ROOT/$name.set" 2>&1 || {
    echo "FAIL: $name could not answer the deferred license question" >&2
    return 1
  }
  grep -Fxq "MIT" "$docs/.throughstone/project-license" || {
    echo "FAIL: $name did not record the answer" >&2
    return 1
  }
  assert_file_contains "$docs/LICENSE" "Copyright (c)"
  assert_file_contains "$docs/LICENSE" "Acme Corp"
  assert_file_contains "$docs/LICENSING.md" "licensed under MIT"
  assert_file_contains "$docs/registries/repos.yml" 'license: "MIT"'
  # Every repo init.sh created carries the same terms, byte for byte.
  cmp -s "$docs/LICENSE" "$work/prompts/LICENSE" || {
    echo "FAIL: $name left the generated repos under different license text" >&2
    return 1
  }
  if grep -rlF 'license: "Unset"' "$docs/registries" >/dev/null 2>&1; then
    echo "FAIL: $name left an unanswered row in the repo inventory" >&2
    return 1
  fi
  if grep -Fq "has not chosen its license yet" "$docs/LICENSING.md"; then
    echo "FAIL: $name left the deferred licensing summary in place" >&2
    return 1
  fi

  # Re-running with the same answer is a no-op; a different one is a relicensing and is refused.
  "$docs/scripts/set-project-license.sh" mit --holder "Acme Corp" >"$TMP_ROOT/$name.again" 2>&1 || {
    echo "FAIL: $name failed on an idempotent re-run" >&2
    return 1
  }
  if "$docs/scripts/set-project-license.sh" private >"$TMP_ROOT/$name.change" 2>&1; then
    echo "FAIL: $name relicensed a project through the answer-once helper" >&2
    return 1
  fi
  assert_file_contains "$TMP_ROOT/$name.change" "already MIT"
  grep -Fxq "MIT" "$docs/.throughstone/project-license" || {
    echo "FAIL: $name changed the posture on a refused relicensing" >&2
    return 1
  }

  # With the question answered, the repo that was refused earlier stamps normally.
  "$docs/scripts/apply-project-license.sh" "$work/early-repo" >"$TMP_ROOT/$name.late" 2>&1 || {
    echo "FAIL: $name could not stamp a repo after the license was chosen" >&2
    return 1
  }
  cmp -s "$docs/LICENSE" "$work/early-repo/LICENSE" || {
    echo "FAIL: $name stamped different license text than the canonical copy" >&2
    return 1
  }
}

# run_license_marker_tamper_case — no generated repo is skipped in silence.
#
# Which repos this helper settles used to be decided by a marker string inside each one's
# LICENSING.md. A repo whose copy had been deleted or edited matched nothing and was skipped
# without a word: the posture was written and the inventory rewritten, while that repo kept no
# LICENSE and no record of why. Unrecoverable afterwards — a second run is refused as an answer
# already given, and apply-project-license.sh refuses a target whose LICENSING.md differs.
#
# Membership is decided by what the directory is (its own git work tree), and the state of its
# LICENSING.md decides what happens: a missing one is written, a deferred one replaced, an edited
# one left alone and named. Both halves are asserted, because recovering the deleted case by
# overwriting the edited one would be a worse bug than the one being fixed.
run_license_marker_tamper_case() {
  local name deleted edited docs

  # (a) LICENSING.md deleted from prompts/ — the repo is still settled.
  name="retcon-license-marker-deleted"
  deleted="$TMP_ROOT/$name"
  copy_template "$deleted"
  ( cd "$deleted" && ./init.sh --non-interactive --mode=existing --slug="$name" \
      --desc="Marker deleted" --layout=multi --collab=solo --remotes=no ) >"$TMP_ROOT/$name.out" 2>&1
  docs="$deleted/Code/$name-docs"
  rm -f "$deleted/prompts/LICENSING.md"
  "$docs/scripts/set-project-license.sh" mit --holder "Acme Corp" >"$TMP_ROOT/$name.set" 2>&1 || {
    echo "FAIL: $name failed after its LICENSING.md was deleted" >&2
    return 1
  }
  [ -f "$deleted/prompts/LICENSE" ] || {
    echo "FAIL: $name left a generated repo unlicensed after its LICENSING.md was deleted" >&2
    return 1
  }
  [ -f "$deleted/prompts/LICENSING.md" ] || {
    echo "FAIL: $name did not restore the licensing summary it had to rewrite anyway" >&2
    return 1
  }

  # (b) LICENSING.md rewritten by hand — left alone, and said out loud.
  name="retcon-license-marker-edited"
  edited="$TMP_ROOT/$name"
  copy_template "$edited"
  ( cd "$edited" && ./init.sh --non-interactive --mode=existing --slug="$name" \
      --desc="Marker edited" --layout=multi --collab=solo --remotes=no ) >"$TMP_ROOT/$name.out" 2>&1
  docs="$edited/Code/$name-docs"
  printf '# Licensing\n\nTBD - ask legal.\n' > "$edited/prompts/LICENSING.md"
  "$docs/scripts/set-project-license.sh" mit --holder "Acme Corp" >"$TMP_ROOT/$name.set" 2>&1 || {
    echo "FAIL: $name failed on a hand-edited licensing summary" >&2
    return 1
  }
  assert_file_contains "$TMP_ROOT/$name.set" "were NOT settled"
  # Named by repo-relative path: the helper reports physical paths, and a fixture under a symlinked
  # temp dir would never match the logical one this test holds.
  assert_file_contains "$TMP_ROOT/$name.set" "$name/prompts/LICENSING.md"
  grep -Fq "ask legal" "$edited/prompts/LICENSING.md" || {
    echo "FAIL: $name overwrote a licensing summary somebody had written" >&2
    return 1
  }
  # And the repos it could settle are still settled — the report is not an abort.
  grep -Fq "has not chosen its license yet" "$docs/LICENSING.md" && {
    echo "FAIL: $name stopped settling the other repos when one was reported" >&2
    return 1
  }

  # (c) An untampered project reports nothing — the warning must not fire on the normal path.
  grep -Fq "were NOT settled" "$TMP_ROOT/retcon-license-marker-deleted.set" && {
    echo "FAIL: $name reported an unsettled repo on a project with none" >&2
    return 1
  }
  return 0
}

# run_posture_visibility_case — an Unset posture is reported by check.sh.
#
# Adoption defers the license question, which is legitimate, so this is a warning and never a
# failure. But nothing reported it at all: a project could sit Unset indefinitely while
# apply-project-license.sh refused to stamp any repo, and the first sign of it was that refusal.
run_posture_visibility_case() {
  local name="retcon-posture-visible"
  local work="$TMP_ROOT/$name" docs
  copy_template "$work"
  ( cd "$work" && ./init.sh --non-interactive --mode=existing --slug="$name" \
      --desc="Posture visibility" --layout=multi --collab=solo --remotes=no ) >"$TMP_ROOT/$name.out" 2>&1
  docs="$work/Code/$name-docs"

  bash "$docs/scripts/check.sh" >"$TMP_ROOT/$name.deferred" 2>&1 || {
    echo "FAIL: $name turned a legitimate deferral into a check.sh failure" >&2
    return 1
  }
  assert_file_contains "$TMP_ROOT/$name.deferred" "has not been chosen yet"
  assert_file_contains "$TMP_ROOT/$name.deferred" "scripts/set-project-license.sh"

  # Once answered, the warning goes away rather than becoming permanent noise.
  "$docs/scripts/set-project-license.sh" apache-2.0 --holder "Acme Corp" >"$TMP_ROOT/$name.set" 2>&1 || {
    echo "FAIL: $name could not answer the deferred question" >&2
    return 1
  }
  bash "$docs/scripts/check.sh" >"$TMP_ROOT/$name.answered" 2>&1 || {
    echo "FAIL: $name check.sh failed after the license was chosen" >&2
    return 1
  }
  if grep -Fq "has not been chosen yet" "$TMP_ROOT/$name.answered"; then
    echo "FAIL: $name still warns about the posture after it was answered" >&2
    return 1
  fi
  assert_file_contains "$TMP_ROOT/$name.answered" "project license posture recorded (Apache-2.0)"
  return 0
}

# run_new_case NAME EXTRA_ARGS... — greenfield must be untouched (marker, no PLAN, message).
run_new_case() {
  local name="$1"; shift
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="A brand-new project" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no \
      "$@"
  ) >"$TMP_ROOT/$name.out" 2>&1

  assert_file_contains "$work/Code/$name-docs/overview.md" "PROJECT-STATUS: not-started"
  if ls "$work/Upcoming Prompts/"*STEP-1-PLAN.md >/dev/null 2>&1; then
    echo "FAIL: $name (new mode) unexpectedly seeded a STEP-1 PLAN" >&2
    return 1
  fi
  if [ -d "$work/Upcoming Prompts/retcon" ]; then
    echo "FAIL: $name (new mode) scaffolded the retcon scratch folder — would misrecover as retcon" >&2
    return 1
  fi
  assert_file_contains "$TMP_ROOT/$name.out" "interview you, propose a roadmap"
  ! grep -Fq "ADOPT your existing codebase" "$TMP_ROOT/$name.out"
}

# run_invalid_mode_case — a bad --mode is rejected before any destructive bootstrap work.
run_invalid_mode_case() {
  local name="retcon-invalid"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  if (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=sideways \
      --slug="$name" \
      --desc="Invalid mode test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1; then
    echo "FAIL: invalid --mode was accepted" >&2
    return 1
  fi

  assert_file_contains "$TMP_ROOT/$name.out" "invalid --mode 'sideways'"
  # Untouched template: the destructive boundary was never crossed.
  [ -d "$work/Code/{{PROJECT}}-docs" ] || { echo "FAIL: template dir was mutated on invalid --mode" >&2; return 1; }
  [ -f "$work/README.md" ] || { echo "FAIL: template files were removed on invalid --mode" >&2; return 1; }
}

# run_marker_recovery_case — simulate marker loss/corruption mid-adoption and assert that the two
# on-disk signals the AGENTS.md "First action" fallback keys on to restore PROJECT-STATUS: retcon
# still hold. The recovery *decision* is agent prose (AGENTS.md 57–64), so what a shell test can
# lock is its INPUTS: an in-flight stub STEP-1 PLAN sitting over a still-bare greenfield STEP-index
# seed. A future init.sh change that broke either signal would make the fallback misfire silently —
# this catches it. (status.sh has no fallback by design: the agent restores the marker first.)
run_marker_recovery_case() {
  local name="retcon-recovery" layout="multi"
  local work="$TMP_ROOT/$name"
  local docs="$work/Code/$name-docs"
  local overview="$docs/overview.md"
  local plan="$work/Upcoming Prompts/$name-STEP-1-PLAN.md"
  local index="$work/prompts/STEP-index.md"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=existing \
      --slug="$name" \
      --desc="Adopt for marker-recovery test" \
      --license=private \
      --layout="$layout" \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  # Precondition: a healthy retcon front door (marker + stub PLAN both present).
  assert_file_contains "$overview" "PROJECT-STATUS: retcon"
  [ -f "$plan" ] || { echo "FAIL: $name precondition — stub PLAN not seeded" >&2; return 1; }

  # Simulate the break: drop the PROJECT-STATUS marker line entirely (marker "missing/corrupted").
  perl -ni -e 'print unless /PROJECT-STATUS:/' "$overview"
  ! grep -q 'PROJECT-STATUS:' "$overview" \
    || { echo "FAIL: $name could not strip the marker for the scenario" >&2; return 1; }

  # Signal (a): an in-flight stub STEP-1 PLAN still sits at the greenfield in-flight path.
  [ -f "$plan" ] || { echo "FAIL: $name recovery signal (a) — in-flight STEP-1 PLAN missing" >&2; return 1; }
  assert_file_contains "$plan" "Retcon baseline"
  # Signal (b): it sits over a STILL-BARE greenfield STEP-index seed (no forward progress yet).
  diff <(sed "s/{{PROJECT}}/$name/g" "$docs/templates/step-index-seed.md") "$index" >/dev/null \
    || { echo "FAIL: $name recovery signal (b) — STEP-index is not the bare greenfield seed" >&2; return 1; }
}

# run_marker_recovery_negative_case — the other half of the AGENTS.md truth table: a fresh
# greenfield checkout, even with its marker stripped, presents NEITHER signal, so it can never be
# misrecovered as a retcon. (run_new_case pins the marker-present half; this pins it under loss.)
run_marker_recovery_negative_case() {
  local name="green-recovery"
  local work="$TMP_ROOT/$name"
  local overview="$work/Code/$name-docs/overview.md"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=new \
      --slug="$name" \
      --desc="Greenfield for marker-recovery test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  perl -ni -e 'print unless /PROJECT-STATUS:/' "$overview"
  # Signal (a) absent: no in-flight STEP-1 PLAN → the fallback cannot mistake greenfield for retcon.
  if ls "$work/Upcoming Prompts/"*STEP-1-PLAN.md >/dev/null 2>&1; then
    echo "FAIL: $name greenfield presents a STEP-1 PLAN — would be misrecovered as retcon" >&2
    return 1
  fi
}

# run_missing_stub_case — a corrupt/incomplete scaffold download (the stub STEP-1 PLAN template is
# absent). init.sh must abort BEFORE flipping the status marker rather than ship a `retcon` project
# with no PLAN: the marker routes every agent to RETCON-PROMPT.md, which reads the stub as a
# precondition and cannot regenerate it, so a marker-without-PLAN state would dead-end the resolver.
run_missing_stub_case() {
  local name="retcon-nostub"
  local work="$TMP_ROOT/$name"
  local overview="$work/Code/$name-docs/overview.md"

  copy_template "$work"
  rm -f "$work/Code/{{PROJECT}}-docs/templates/retcon-step-1-plan-stub.md"
  if (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --mode=existing \
      --slug="$name" \
      --desc="Missing stub template" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1; then
    echo "FAIL: init.sh accepted a missing stub STEP-1 PLAN template" >&2
    return 1
  fi

  assert_file_contains "$TMP_ROOT/$name.out" "stub STEP-1 PLAN template is missing"
  # The load-bearing marker must NOT have been flipped — no half-adopted `retcon` state ships.
  ! grep -Fq "PROJECT-STATUS: retcon" "$overview" \
    || { echo "FAIL: $name flipped the marker despite the missing stub template" >&2; return 1; }
  # And no PLAN was seeded at the in-flight path.
  if ls "$work/Upcoming Prompts/"*STEP-1-PLAN.md >/dev/null 2>&1; then
    echo "FAIL: $name seeded a STEP-1 PLAN despite the missing template" >&2
    return 1
  fi
}

run_existing_case "retcon-multi" multi
run_existing_case "retcon-mono"  mono
run_existing_env_case
run_deferred_license_case
run_set_project_license_case
run_license_marker_tamper_case
run_posture_visibility_case
run_new_case "green-explicit" --mode=new
run_new_case "green-default"
run_invalid_mode_case
run_missing_stub_case
run_marker_recovery_case
run_marker_recovery_negative_case

echo "init.sh new-vs-existing fork (retcon): PASS"
