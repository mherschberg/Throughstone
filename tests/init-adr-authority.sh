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

# The template marker is the substitution authority. It must exist in the scaffold so solo and
# team bootstraps can replace it instead of relying on incidental prose.
grep -Fq '<!-- ADR-AUTHORITY -->_solo author_<!-- /ADR-AUTHORITY -->' \
  "$ROOT/Code/{{PROJECT}}-docs/adr/README.md"

# Solo projects should materialize the default solo author authority and remove the marker.
run_init_case "adr-solo" --collab=solo
solo_adr="$TMP_ROOT/adr-solo/Code/adr-solo-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** _solo author_' "$solo_adr"
! grep -Fq 'ADR-AUTHORITY' "$solo_adr"

# Team projects should use the configured authority everywhere and never leak the solo
# default or marker syntax into the generated ADR registry.
run_init_case "adr-team" --collab=team --adr-authority="ADR review on PR"
team_adr="$TMP_ROOT/adr-team/Code/adr-team-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** ADR review on PR' "$team_adr"
! grep -Fq '_solo author_' "$team_adr"
! grep -Fq 'ADR-AUTHORITY' "$team_adr"
grep -Fq 'ADR authority: ADR review on PR' "$TMP_ROOT/adr-team.out"

echo "init.sh ADR authority marker substitution: PASS"
