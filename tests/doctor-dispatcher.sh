#!/usr/bin/env bash
#
# Regression coverage for the root doctor.sh dispatcher.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-doctor-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# assert_contains OUTPUT EXPECTED — preserve only the dispatch contract sentence so helper
# output can evolve independently.
assert_contains() {
  local output="$1" expected="$2"
  if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
    printf 'FAIL: expected output to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

# Build a minimal generated-workspace shape with fake helper scripts. The dispatcher test
# cares that doctor.sh finds and execs the right helper while forwarding any extra arguments;
# status.sh/check.sh behavior is covered by their own tests.
fixture="$TMP_ROOT/workspace"
mkdir -p "$fixture/Code/acme-docs/scripts"
cp -p "$ROOT/doctor.sh" "$fixture/doctor.sh"
cp -p "$ROOT/Code/{{PROJECT}}-docs/scripts/doctor.sh" \
  "$fixture/Code/acme-docs/scripts/doctor.sh"

cat > "$fixture/Code/acme-docs/scripts/status.sh" <<'STATUS'
#!/usr/bin/env bash
printf 'status helper: %s\n' "$*"
STATUS
chmod +x "$fixture/Code/acme-docs/scripts/status.sh"

cat > "$fixture/Code/acme-docs/scripts/check.sh" <<'CHECK'
#!/usr/bin/env bash
printf 'check helper: %s\n' "$*"
CHECK
chmod +x "$fixture/Code/acme-docs/scripts/check.sh"

cat > "$fixture/Code/acme-docs/scripts/links.sh" <<'LINKS'
#!/usr/bin/env bash
printf 'links helper: %s\n' "$*"
LINKS
chmod +x "$fixture/Code/acme-docs/scripts/links.sh"

# Help output is the user-facing command list; keep it explicit so new commands are deliberate.
help_output="$("$ROOT/doctor.sh" --help)"
assert_contains "$help_output" "Usage: ./doctor.sh <command> [args]"
assert_contains "$help_output" "status"
assert_contains "$help_output" "check"
assert_contains "$help_output" "links"

# The implemented commands should be thin pass-throughs to the docs-hub helpers.
output="$("$fixture/doctor.sh" status alpha beta)"
assert_contains "$output" "status helper: alpha beta"

output="$("$fixture/doctor.sh" check --verbose)"
assert_contains "$output" "check helper: --verbose"

output="$("$fixture/doctor.sh" links --sample)"
assert_contains "$output" "links helper: --sample"

# Multi-repo workspace roots are per-machine and not committed, so setup-workspace.sh must
# regenerate the root dispatcher for later developers' machines.
setup_fixture="$TMP_ROOT/setup-workspace"
mkdir -p "$setup_fixture/Code"
cp -R "$ROOT/Code/{{PROJECT}}-docs" "$setup_fixture/Code/acme-docs"
"$setup_fixture/Code/acme-docs/scripts/setup-workspace.sh" > "$TMP_ROOT/setup-workspace.out"
[ -x "$setup_fixture/doctor.sh" ] || {
  printf 'FAIL: setup-workspace.sh did not create an executable root doctor.sh\n' >&2
  exit 1
}
setup_fixture_abs="$(cd "$setup_fixture" && pwd)"
output="$("$setup_fixture/doctor.sh" status)"
assert_contains "$output" "Throughstone status — $setup_fixture_abs"

# Unknown commands should fail before reaching a helper and use a stable CLI error code.
set +e
unknown_output="$("$fixture/doctor.sh" nope 2>&1)"
unknown_status=$?
set -e
[ "$unknown_status" -eq 2 ] || {
  printf 'FAIL: expected unknown command to exit 2, got %s\n' "$unknown_status" >&2
  exit 1
}
assert_contains "$unknown_output" "unknown command: nope"

echo "doctor.sh dispatcher: PASS"
