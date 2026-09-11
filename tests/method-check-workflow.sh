#!/usr/bin/env bash
#
# Regression coverage for the method-check workflow every generated project ships
# (.github/workflows/method-check.yml): the commands in its doctor step must fail when the doctor
# fails, and succeed when it passes. Only those commands are run; the step's other keys are not
# read.
#
# The step is run the way GitHub Actions runs a `shell: bash` step — `bash --noprofile --norc -eo
# pipefail`, with CI set — from the root of a fresh clone of the repository the workflow sits in.
# It looks for the doctor in two places, and both are run: scripts/check.sh at the root of a docs
# hub that is its own repository, as in multi-repo CI, and Code/<project>-docs/scripts/check.sh
# under a mono project's workspace root.
#
# Nothing here parses YAML, so the step is lifted out of the workflow as text. A wrong lift cannot
# pass: an empty one is reported, and every run must print the doctor's own RESULT line, so a step
# that never reaches the doctor fails its case.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-method-check-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

SLUG="gate"
WORKFLOW=".github/workflows/method-check.yml"
failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

# copy_template DEST — build a template fixture from HEAD, then overlay current worktree
# changes. Archiving rather than copying the live tree leaves ignored maintainer files behind,
# so the fixture is the shape a user downloads; the overlay keeps uncommitted edits under test.
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

# bootstrap LAYOUT — generate a project in that layout and echo its workspace root.
bootstrap() {
  local work="$TMP_ROOT/$1"
  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$SLUG" \
      --desc="Method-check workflow test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout="$1" \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$1.init.out" 2>&1 || {
    bad "$1: init.sh failed"
    sed -n '1,40p' "$TMP_ROOT/$1.init.out" >&2
    return 1
  }
  printf '%s\n' "$work"
}

# doctor_step FILE — print the `run: |` block of the step named "Run method doctor", without its
# YAML indentation. The block ends at the first line indented no deeper than its `run:` key.
doctor_step() {
  awk '
    /^[[:space:]]*- name: Run method doctor/ { step = 1; next }
    step && !body && /^[[:space:]]*run:[[:space:]]*\|[[:space:]]*$/ { match($0, /^ */); key = RLENGTH; body = 1; next }
    body {
      blank = ($0 ~ /^[[:space:]]*$/)
      match($0, /^ */)
      if (!blank && RLENGTH <= key) exit
      if (!blank && !ind) ind = RLENGTH
      print substr($0, ind + 1)
    }
  ' "$1"
}

# drift HUB — give the docs hub an architecture document with none of its required fields: one
# hard failure, which the doctor reports in either layout.
drift() {
  mkdir -p "$1/architecture"
  printf '# Drift\n' > "$1/architecture/01-drift.md"
}

# gate LABEL REPO HUB [BREAK] — clone REPO in place of the job's checkout step, run BREAK on the
# docs hub inside the clone (HUB is its path there), then run the doctor step from the clone's
# root. The clone sits two levels down because the doctor takes the workspace root to be two
# folders above the docs hub, and that must stay inside this test's directory. GATE_STATUS is the
# step's exit status and GATE_OUT what it printed.
gate() {
  local label="$1" repo="$2" hub="$3" break_with="${4:-}" clone step
  clone="$TMP_ROOT/$label/ci/$(basename "$repo")"
  step="$TMP_ROOT/$label.step.sh"
  git clone -q "$repo" "$clone" || { bad "$label: could not clone $repo"; return 1; }
  [ -z "$break_with" ] || "$break_with" "$clone/$hub"
  doctor_step "$clone/$WORKFLOW" > "$step"
  [ -s "$step" ] || { bad "$label: found no run step under \"Run method doctor\" in $WORKFLOW"; return 1; }
  GATE_OUT="$(cd "$clone" && CI=true bash --noprofile --norc -eo pipefail "$step" 2>&1)"
  GATE_STATUS=$?
}

# outcome LABEL WANT — WANT is pass or fail. The step's exit status must agree, and the doctor
# must have printed the matching RESULT line.
outcome() {
  local label="$1" want="$2" result=OK
  if [ "$want" = pass ]; then
    [ "$GATE_STATUS" -eq 0 ] || bad "$label — expected the step to succeed, got exit $GATE_STATUS"
  else
    result=FAIL
    [ "$GATE_STATUS" -ne 0 ] || bad "$label — expected the step to fail, got exit 0"
  fi
  case "$GATE_OUT" in
    *"RESULT: $result"*) ;;
    *) bad "$label — expected the doctor to run to RESULT: $result"; printf '%s\n' "$GATE_OUT" | tail -5 >&2 ;;
  esac
}

multi="$(bootstrap multi)" || exit 1
mono="$(bootstrap mono)"   || exit 1

# A docs hub that is its own repository: CI checks out the hub, and the step finds scripts/check.sh
# at its root.
gate hub-healthy "$multi/Code/$SLUG-docs" . && outcome "hub repository, healthy project" pass
gate hub-failing "$multi/Code/$SLUG-docs" . drift && outcome "hub repository, doctor failing" fail

# A mono project: CI checks out the workspace root, and the step finds the docs hub under Code/.
gate mono-healthy "$mono" "Code/$SLUG-docs" && outcome "mono workspace root, healthy project" pass
gate mono-failing "$mono" "Code/$SLUG-docs" drift && outcome "mono workspace root, doctor failing" fail

if [ "$failures" -ne 0 ]; then
  printf 'method-check workflow: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
echo "method-check workflow: PASS"
