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
  grep -Fq "$2" "$1" || { echo "FAIL: '$2' not found in $1" >&2; return 1; }
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
  assert_file_contains "$docs/templates/reports/recon-map-report-template.md" \
    "Licensing is recorded as found, never set here"
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

# run_license_scope_note_case — the interactive license/holder questions say what they cover when
# adopting an existing codebase, and say nothing extra when starting from scratch. Without the
# note the questions read as "what is your code licensed under?", which is not what they set:
# a user answering about their existing repos would be choosing the docs hub's license instead.
run_license_scope_note_case() {
  local name="retcon-license-note" green="green-license-note"
  local work="$TMP_ROOT/$name" green_work="$TMP_ROOT/$green"
  local note="NOT the code you're adopting"

  # Answers, in order: mode=existing, open source, MIT, copyright holder.
  copy_template "$work"
  (
    cd "$work"
    printf '2\n1\n1\nThroughstone Test\n' | ./init.sh \
      --slug="$name" \
      --desc="Adoption license scope note" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  assert_file_contains "$TMP_ROOT/$name.out" "$note"
  # The note must precede the questions it scopes — after the fact it explains nothing.
  [ "$(grep -n "$note" "$TMP_ROOT/$name.out" | head -1 | cut -d: -f1)" \
    -lt "$(grep -n "Is this project open source" "$TMP_ROOT/$name.out" | head -1 | cut -d: -f1)" ] || {
    echo "FAIL: $name printed the scope note after the license question" >&2
    return 1
  }
  assert_file_contains "$work/Code/$name-docs/overview.md" "PROJECT-STATUS: retcon"

  # Greenfield creates every repo it licenses, so there is nothing to scope and no note.
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

  if grep -Fq "$note" "$TMP_ROOT/$green.out"; then
    echo "FAIL: $green printed the adoption license-scope note" >&2
    return 1
  fi
  assert_file_contains "$green_work/Code/$green-docs/overview.md" "PROJECT-STATUS: not-started"
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
run_license_scope_note_case
run_new_case "green-explicit" --mode=new
run_new_case "green-default"
run_invalid_mode_case
run_missing_stub_case
run_marker_recovery_case
run_marker_recovery_negative_case

echo "init.sh new-vs-existing fork (retcon): PASS"
