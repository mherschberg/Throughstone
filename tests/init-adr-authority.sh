#!/usr/bin/env bash
#
# Regression coverage for init.sh ADR authority marker substitution for solo vs team
# projects.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-adr-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree
# changes. The overlay keeps comment-pass and bootstrap edits under test before they are
# committed, while leaving Git metadata behind so init.sh sees a downloaded template.
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

# run_init_case NAME ARGS... — bootstrap one private multi-repo fixture and keep stdout for
# assertions about generated collaboration metadata.
run_init_case() {
  local name="$1"
  shift
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="ADR authority marker test" \
      --license=private \
      --layout=multi \
      --remotes=no \
      "$@"
  ) >"$TMP_ROOT/$name.out" 2>&1
}

# assert_absent FILE TEXT — fail when TEXT appears in FILE. Negative assertions are written this
# way rather than as a top-level `! grep -Fq ...`: bash exempts a `!`-inverted command from
# set -e, so a bare inverted grep mid-script has nowhere for its status to land. All three of the
# ones below were inert for exactly that reason — a substitution that left every marker and the
# solo default in place still reported PASS, because the script's status was the closing echo.
assert_absent() {
  local file="$1" text="$2"
  if [ ! -f "$file" ]; then
    printf 'FAIL: expected %s to exist\n' "$file" >&2
    exit 1
  fi
  if grep -Fq "$text" "$file"; then
    printf 'FAIL: expected %s not to contain: %s\n' "$file" "$text" >&2
    exit 1
  fi
}

# The template marker is the substitution authority. It must exist in the scaffold so solo and
# team bootstraps can replace it instead of relying on incidental prose.
grep -Fq '<!-- ADR-AUTHORITY -->_solo author_<!-- /ADR-AUTHORITY -->' \
  "$ROOT/Code/{{PROJECT}}-docs/adr/README.md"

# Solo projects should materialize the default solo author authority and remove the marker.
run_init_case "adr-solo" --collab=solo
solo_adr="$TMP_ROOT/adr-solo/Code/adr-solo-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** _solo author_' "$solo_adr"
assert_absent "$solo_adr" 'ADR-AUTHORITY'

# Team projects should use the configured authority everywhere and never leak the solo
# default or marker syntax into the generated ADR registry.
run_init_case "adr-team" --collab=team --adr-authority="ADR review on PR"
team_adr="$TMP_ROOT/adr-team/Code/adr-team-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** ADR review on PR' "$team_adr"
assert_absent "$team_adr" '_solo author_'
assert_absent "$team_adr" 'ADR-AUTHORITY'
grep -Fq 'ADR authority: ADR review on PR' "$TMP_ROOT/adr-team.out"

echo "init.sh ADR authority marker substitution: PASS"
