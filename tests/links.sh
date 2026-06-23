#!/usr/bin/env bash
#
# Regression coverage for the durable-docs stale-link checker.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-links-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

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
  "$fixture/prompts" \
  "$fixture/Upcoming Prompts"

cp -p "$ROOT/Code/{{PROJECT}}-docs/scripts/links.sh" "$fixture/Code/acme-docs/scripts/links.sh"

cat > "$fixture/README.md" <<'README'
# Root Readme

See [docs](Code/acme-docs/README.md), [local heading](#root-readme), and
[defined reference][docs-ref], and [repo-hosted discussions](../../discussions).

[docs-ref]: Code/acme-docs/README.md
README

cat > "$fixture/ARTIFACT-TRAIL.md" <<'ARTIFACTS'
# Artifact Trail

See [docs](Code/acme-docs/README.md).
ARTIFACTS

cat > "$fixture/Code/acme-docs/README.md" <<'DOCS'
# Docs Hub

See [the runbook](runbooks/check-in.md#check-in) and [the root readme](../../README.md).
External links such as [example](https://example.com) are skipped.
DOCS

cat > "$fixture/Code/acme-docs/runbooks/check-in.md" <<'RUNBOOK'
# Check In
RUNBOOK

cat > "$fixture/Code/acme-docs/templates/generated.md" <<'TEMPLATE'
# Generated Template

This generated-context link should not be checked here: [future file](future-output.md).
TEMPLATE

cat > "$fixture/prompts/legacy.md" <<'PROMPTS'
[legacy missing](missing.md)
PROMPTS

cat > "$fixture/Upcoming Prompts/active.md" <<'UPCOMING'
[active missing](missing.md)
UPCOMING

output="$("$fixture/Code/acme-docs/scripts/links.sh")"
assert_contains "$output" "RESULT: OK"

cat > "$fixture/Code/acme-docs/broken.md" <<'BROKEN'
# Broken

[missing file](missing.md)
[missing anchor](runbooks/check-in.md#missing-anchor)
[undefined reference][missing-ref]
BROKEN

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
assert_contains "$output" "uses undefined reference link: [missing-ref]"

echo "links.sh: PASS"
