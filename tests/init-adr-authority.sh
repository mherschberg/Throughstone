#!/usr/bin/env bash
#
# Regression coverage for init.sh ADR authority marker substitution.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-adr-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — copy HEAD plus current working-tree changes, without Git metadata.
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

grep -Fq '<!-- ADR-AUTHORITY -->_solo author_<!-- /ADR-AUTHORITY -->' \
  "$ROOT/Code/{{PROJECT}}-docs/adr/README.md"

run_init_case "adr-solo" --collab=solo
solo_adr="$TMP_ROOT/adr-solo/Code/adr-solo-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** _solo author_' "$solo_adr"
! grep -Fq 'ADR-AUTHORITY' "$solo_adr"

run_init_case "adr-team" --collab=team --adr-authority="ADR review on PR"
team_adr="$TMP_ROOT/adr-team/Code/adr-team-docs/adr/README.md"
grep -Fq '**Who accepts an ADR in this project:** ADR review on PR' "$team_adr"
! grep -Fq '_solo author_' "$team_adr"
! grep -Fq 'ADR-AUTHORITY' "$team_adr"
grep -Fq 'ADR authority: ADR review on PR' "$TMP_ROOT/adr-team.out"

echo "init.sh ADR authority marker substitution: PASS"
