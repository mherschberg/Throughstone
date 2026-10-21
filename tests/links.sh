#!/usr/bin/env bash
#
# Regression coverage for the durable-docs stale-link checker.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-links-test.XXXXXX")"
# The last checks below make folders that cannot be listed, and rm -rf cannot empty those.
trap 'chmod -R u+rwx "$TMP_ROOT" 2>/dev/null; rm -rf "$TMP_ROOT"' EXIT

assert_contains() {
  local output="$1" expected="$2"
  if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
    printf 'FAIL: expected output to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

fixture="$TMP_ROOT/workspace"
mkdir -p "$fixture/Code/acme-docs/scripts" \
  "$fixture/Code/acme-docs/runbooks" \
  "$fixture/Code/acme-docs/templates" \
  "$fixture/Code/acme-docs/inputs/archive" \
  "$fixture/prompts" \
  "$fixture/Upcoming Prompts"

cp -p "$ROOT/Code/{{PROJECT}}-docs/scripts/links.sh" "$fixture/Code/acme-docs/scripts/links.sh"

cat > "$fixture/README.md" <<'README'
# Root Readme

See [docs](Code/acme-docs/README.md), [local heading](#root-readme), and
[defined reference][docs-ref], and [repo-hosted discussions](../../discussions).

[docs-ref]: Code/acme-docs/README.md
README

# A link can climb out of the workspace and come back in under another name, here through a
# symlink beside it. It lands inside the workspace, so it is checked like any other link.
ln -s workspace "$TMP_ROOT/workspace-alias"
printf '\n[back in](../workspace-alias/Code/acme-docs/README.md)\n' >> "$fixture/README.md"

cat > "$fixture/ARTIFACT-TRAIL.md" <<'ARTIFACTS'
# Artifact Trail

See [docs](Code/acme-docs/README.md).
ARTIFACTS

# links.sh is scoped to four root files by name, and two of them are the pointers the whole method
# depends on.
cat > "$fixture/AGENTS.md" <<'AGENTSMD'
# Agents

Context lives in [the docs hub](Code/acme-docs/README.md).
AGENTSMD

cat > "$fixture/CLAUDE.md" <<'CLAUDEMD'
# Claude

Context lives in [the docs hub](Code/acme-docs/README.md).
CLAUDEMD

# Everything a link parser must NOT read: a fenced block, an HTML comment, and an inline code
# span. Each names a file that does not exist, so if the suppression engine stops suppressing,
# the clean run below reports findings instead of RESULT: OK.
cat > "$fixture/Code/acme-docs/suppressed.md" <<'SUPPRESSED'
# Suppressed

```markdown
[in a fenced block](never-written.md)
```

<!--
[in an HTML comment](never-written.md)
-->

A link written as `[inline code](never-written.md)` is an example, not a link.
SUPPRESSED

# A heading with a symbol between spaces gets one hyphen for each space, as on GitHub, so the link
# to "Risks & mitigations" below must pass.
cat > "$fixture/Code/acme-docs/README.md" <<'DOCS'
# Docs Hub

See [the runbook](runbooks/check-in.md#check-in),
[its risks](runbooks/check-in.md#risks--mitigations) and [the root readme](../../README.md).
External links such as [example](https://example.com) are skipped.
DOCS

cat > "$fixture/Code/acme-docs/runbooks/check-in.md" <<'RUNBOOK'
# Check In

## Risks & mitigations
RUNBOOK

cat > "$fixture/Code/acme-docs/templates/generated.md" <<'TEMPLATE'
# Generated Template

This generated-context link should not be checked here: [future file](future-output.md).
TEMPLATE

# Imported documents are kept as they arrived, so a broken link in one must not fail the run. Each
# link climbs out of inputs/ and lands on a missing path inside the workspace; one above the
# workspace root is skipped anyway and would prove nothing. A fully captured input is moved to
# inputs/archive/, so retired.md below sits there: a skip covering only the top of inputs/ would
# let its broken link fail the run.
cat > "$fixture/Code/acme-docs/inputs/imported.md" <<'INPUT'
# Imported Spec

See [the service spec](../../../src/spec.md).
INPUT

cat > "$fixture/Code/acme-docs/inputs/archive/retired.md" <<'ARCHIVED'
# Retired Spec

See [the old service spec](../../../../src/spec.md).
ARCHIVED

cat > "$fixture/prompts/legacy.md" <<'PROMPTS'
[legacy missing](missing.md)
PROMPTS

cat > "$fixture/Upcoming Prompts/active.md" <<'UPCOMING'
[active missing](missing.md)
UPCOMING

output="$("$fixture/Code/acme-docs/scripts/links.sh")"
assert_contains "$output" "RESULT: OK"

# Runbooks/ below has the wrong letter case, and so does MIRROR/, the name of a symlink to the hub.
# A case-insensitive disk, such as macOS's, opens both anyway, so the links work there and break on
# a case-sensitive one. Resolving the symlink would hide the second. The last link writes the
# "Risks & mitigations" anchor with one hyphen, which is dead on GitHub, so it must fail.
ln -s acme-docs "$fixture/Code/mirror"
cat > "$fixture/Code/acme-docs/broken.md" <<'BROKEN'
# Broken

[missing file](missing.md)
[missing anchor](runbooks/check-in.md#missing-anchor)
[undefined reference][missing-ref]
[wrong case](Runbooks/check-in.md)
[wrong-case symlink](../MIRROR/runbooks/check-in.md)
[collapsed anchor](runbooks/check-in.md#risks-mitigations)
BROKEN

# A broken link in a root pointer has to be reported too. The clean run is checked only for
# RESULT: OK, which holds whether or not AGENTS.md is read, so a finding attributed to AGENTS.md
# is what shows that the file is in scope.
printf '\n[pointer to nowhere](never-written.md)\n' >> "$fixture/AGENTS.md"

# A missing file reached through the symlink beside the workspace is reported like any other.
printf '\n[missing, back in](../workspace-alias/never-written.md)\n' >> "$fixture/README.md"

set +e
output="$("$fixture/Code/acme-docs/scripts/links.sh" 2>&1)"
status=$?
set -e

[ "$status" -eq 1 ] || {
  printf 'FAIL: expected links.sh to exit 1, got %s\n' "$status" >&2
  printf '%s\n' "$output" >&2
  exit 1
}
assert_contains "$output" "links to missing file: missing.md"
assert_contains "$output" "links to missing anchor: runbooks/check-in.md#missing-anchor"
assert_contains "$output" \
  "broken.md:8 links to missing anchor: runbooks/check-in.md#risks-mitigations"
assert_contains "$output" "uses undefined reference link: [missing-ref]"
assert_contains "$output" "broken.md:6 links to path with wrong case: Runbooks/check-in.md"
assert_contains "$output" "→ fix: use Code/acme-docs/runbooks/check-in.md"
assert_contains "$output" \
  "broken.md:7 links to path with wrong case: ../MIRROR/runbooks/check-in.md"
assert_contains "$output" "AGENTS.md:5 links to missing file: never-written.md"
assert_contains "$output" \
  "README.md:10 links to missing file: ../workspace-alias/never-written.md"

# The letter-case check lists each folder on a link's path. A folder above the workspace that
# cannot be listed must not matter, and one inside it that cannot be listed is a finding, not a
# crash. Mode 111 lets a folder be entered but not listed, except by a user who can list any
# folder, such as root. There the checks are skipped, since they would test nothing.
locked="$TMP_ROOT/locked"
hub="$locked/workspace/Code/acme-docs"
mkdir -p "$hub/scripts" "$hub/sealed"
cp -p "$ROOT/Code/{{PROJECT}}-docs/scripts/links.sh" "$hub/scripts/links.sh"
printf '# Root Readme\n' > "$locked/workspace/README.md"
printf '# Docs Hub\n\nSee [the root readme](../../README.md).\n' > "$hub/README.md"
printf '# Sealed\n' > "$hub/sealed/page.md"
chmod 111 "$locked"
if ls "$locked" >/dev/null 2>&1; then
  echo "links.sh: skipping the unlistable-folder checks: this user can list a mode-111 folder"
else
  set +e
  output="$("$hub/scripts/links.sh" 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    printf 'FAIL: expected links.sh under an unlistable parent to exit 0, got %s\n' "$status" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
  assert_contains "$output" "RESULT: OK"

  printf '\nSee [a sealed page](sealed/page.md).\n' >> "$hub/README.md"
  chmod 111 "$hub/sealed"
  set +e
  output="$("$hub/scripts/links.sh" 2>&1)"
  status=$?
  set -e
  chmod 755 "$hub/sealed" "$locked"
  [ "$status" -eq 1 ] || {
    printf 'FAIL: expected links.sh to exit 1 on an unlistable folder, got %s\n' "$status" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
  assert_contains "$output" \
    "[FAIL] Code/acme-docs/README.md:5 links through a folder that cannot be listed: sealed/page.md"
  assert_contains "$output" "→ fix: give read access to Code/acme-docs/sealed"
  assert_contains "$output" "RESULT: FAIL"
fi

echo "links.sh: PASS"
