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
#   - Marker-loss recovery: with PROJECT-STATUS stripped mid-adoption, the shipped recovery rule
#     tells the agent to ASK the project's human which mode this is, and neither AGENTS.md nor
#     status.sh asks it to work that out from the files.

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
# run_status_for WORK OVERVIEW INDEX — status.sh against one project's files, from its root.
run_status_for() {
  ( cd "$1" && THROUGHSTONE_OVERVIEW="$2" THROUGHSTONE_STEP_INDEX="$3" \
      "$1/Code/$(basename "$1")-docs/scripts/status.sh" )
}

# assert_marker_ask NAME OUTPUT — the missing-marker guard reports indeterminate, sends the agent to
# the person, resolves nothing, and prints no trace of the removed seed-comparison inference.
assert_marker_ask() {
  local name="$1" out="$2" needle
  printf '%s\n' "$out" | grep -Fq 'indeterminate' \
    || { echo "FAIL: $name status.sh did not report indeterminate" >&2; return 1; }
  printf '%s\n' "$out" | grep -Fq 'Ask whoever owns this project' \
    || { echo "FAIL: $name status.sh did not tell the reader to ask" >&2; return 1; }
  for needle in 'still-bare STEP-index seed' 'infers the mode from disk' 'Run STEP-1.1'; do
    if printf '%s\n' "$out" | grep -Fq "$needle"; then
      echo "FAIL: $name status.sh still prints \"$needle\"" >&2
      return 1
    fi
  done
}

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

  # 2b. Pre-answer-sheet scratch folder scaffolded (a home for Stage-3 sheets).
  [ -d "$work/Upcoming Prompts/retcon" ] \
    || { echo "FAIL: $name did not scaffold Upcoming Prompts/retcon/" >&2; return 1; }
  assert_file_contains "$work/Upcoming Prompts/retcon/README.md" "pre-answer sheet"

  # 3. At bootstrap the STEP index is byte-identical to the greenfield seed (slug-substituted):
  #    adoption adds nothing to it here. This pins what init.sh PRODUCES; it is not a test of
  #    project history, and nothing may decide what mode a project is in by re-running it later
  #    (substep 1.2 fills the Phase 1 heading before the baseline lands).
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

  # 6. The bootstrap hand-off explains adoption, not the greenfield interview.
  #    Key on a distinctive phrase, not the substring "retcon" (which may sit inside the slug).
  assert_file_contains "$TMP_ROOT/$name.out" "ADOPT your existing codebase"
  ! grep -Fq "interview you, propose a roadmap" "$TMP_ROOT/$name.out"
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
    echo "FAIL: $name (new mode) scaffolded the retcon scratch folder" >&2
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

# run_marker_recovery_case — simulate marker loss/corruption mid-adoption and assert the shipped
# recovery contract: the agent ASKS the project's human which mode this is. The recovery *decision*
# is agent prose (AGENTS.md "First action"), so what a shell test can lock is the instruction the
# project actually ships — that it directs the agent to ask, and that it no longer directs anyone to
# decide the question by comparing prompts/STEP-index.md against its init.sh seed. That comparison
# cannot answer it: substep 1.2 is required to fill the `## Phase 1 — {{PHASE_1_NAME}}` heading
# before the baseline lands, so a mid-adoption index legitimately differs from the seed.
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

  # The answer must not depend on the index at all. Take it once with the index at its seed, then
  # again after substep 1.2's sanctioned fill of the Phase 1 heading — the edit that used to flip
  # this project from "retcon" to "resume" — and require the two to be identical.
  local before after
  before="$(run_status_for "$work" "$overview" "$index")" \
    || { echo "FAIL: $name status.sh exited non-zero on a missing marker" >&2; return 1; }

  perl -pi -e 's/^## Phase 1 — \{\{PHASE_1_NAME\}\}$/## Phase 1 — Harden the baseline/' "$index"
  if diff <(sed "s/{{PROJECT}}/$name/g" "$docs/templates/step-index-seed.md") "$index" >/dev/null; then
    echo "FAIL: $name scenario setup — the 1.2 fill did not change the index" >&2
    return 1
  fi
  after="$(run_status_for "$work" "$overview" "$index")" \
    || { echo "FAIL: $name status.sh exited non-zero once the index was filled" >&2; return 1; }

  if [ "$before" != "$after" ]; then
    echo "FAIL: $name status.sh answered differently once substep 1.2 filled the index" >&2
    return 1
  fi
  assert_marker_ask "$name" "$after" || return 1

  # The contract in the shipped prose: AGENTS.md sends the agent to the human, and carries neither
  # half of the old two-signal inference (the bare-seed index, and the in-flight STEP-1 PLAN).
  assert_file_contains "$docs/AGENTS.md" "ask the project's human which mode this is"
  assert_file_contains "$docs/AGENTS.md" "Do not infer it from the files"
  local ghost
  for ghost in 'bare `init.sh` seed' 'still-bare' 'means a **retcon** whose marker' 'infer from disk'; do
    if grep -Fq "$ghost" "$docs/AGENTS.md"; then
      echo "FAIL: $name AGENTS.md still works the mode out from disk (\"$ghost\")" >&2
      return 1
    fi
  done
}

# run_marker_recovery_negative_case — the greenfield half of the same contract. A fresh greenfield
# checkout with its marker stripped is just as indeterminate as an adopted one: status.sh must not
# resolve a next action for it either, and must route it to the same ask. (run_new_case pins the
# marker-present half; this pins it under loss.)
run_marker_recovery_negative_case() {
  local name="green-recovery"
  local work="$TMP_ROOT/$name"
  local docs="$work/Code/$name-docs"
  local overview="$docs/overview.md"
  local index="$work/prompts/STEP-index.md"

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

  # This tree is the structural opposite of the adopted one — no in-flight PLAN, no scratch folder,
  # and an index still at its seed. Under the old rule that combination decided the answer; it must
  # now make no difference, so the same ask comes back.
  if ls "$work/Upcoming Prompts/"*STEP-1-PLAN.md >/dev/null 2>&1; then
    echo "FAIL: $name greenfield unexpectedly carries an in-flight STEP-1 PLAN" >&2; return 1
  fi
  [ ! -d "$work/Upcoming Prompts/retcon" ] \
    || { echo "FAIL: $name greenfield unexpectedly carries the retcon scratch folder" >&2; return 1; }
  diff <(sed "s/{{PROJECT}}/$name/g" "$docs/templates/step-index-seed.md") "$index" >/dev/null \
    || { echo "FAIL: $name greenfield index is not at its seed — scenario invalid" >&2; return 1; }

  local out
  out="$(run_status_for "$work" "$overview" "$index")" \
    || { echo "FAIL: $name status.sh exited non-zero on a missing marker" >&2; return 1; }
  assert_marker_ask "$name" "$out" || return 1
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
run_new_case "green-explicit" --mode=new
run_new_case "green-default"
run_invalid_mode_case
run_missing_stub_case
run_marker_recovery_case
run_marker_recovery_negative_case

echo "init.sh new-vs-existing fork (retcon): PASS"
