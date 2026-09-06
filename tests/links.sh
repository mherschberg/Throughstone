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

# links.sh is scoped to four root files by name, and two of them are the pointers the whole method
# depends on. The fixture never created either, so nothing here checked that they are looked at.
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
# the clean run below reports findings instead of RESULT: OK. Nothing exercised those 29 lines
# before, and the whole engine could be replaced with a passthrough with this test still green.
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

# A broken link in a root pointer has to be reported too. Creating AGENTS.md above proves it is
# parsed; only a finding attributed to it proves it is in scope. Dropping the two pointers from
# the scoped list is otherwise invisible — they are the files the method depends on most.
printf '\n[pointer to nowhere](never-written.md)\n' >> "$fixture/AGENTS.md"

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
assert_contains "$output" "AGENTS.md:5 links to missing file: never-written.md"

echo "links.sh: PASS"
