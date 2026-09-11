#!/usr/bin/env bash
#
# Regression coverage for the brand/site -> docs GitHub Pages publish contract.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-site-publish-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

"$ROOT/brand/publish-site.sh" --check

grep -Fxq 'throughstone.org' "$ROOT/docs/CNAME" || {
  printf 'FAIL: docs/CNAME must contain throughstone.org\n' >&2
  exit 1
}

[ -f "$ROOT/docs/.nojekyll" ] || {
  printf 'FAIL: docs/.nojekyll is missing\n' >&2
  exit 1
}

# --check never publishes. Run a real publish with a copy of the script, in a throwaway brand/ and
# docs/ laid out where the script looks for them from its own path. docs/ starts with both Pages
# files, which the script refuses to run without, and with what an earlier publish leaves behind:
# a page brand/site/ no longer has, and a stale file inside a folder it still has.
site="$TMP_ROOT/brand/site"
pages="$TMP_ROOT/docs"
mkdir -p "$site/sub" "$pages/sub"
cp -p "$ROOT/brand/publish-site.sh" "$TMP_ROOT/brand/publish-site.sh"
printf '<p>index</p>\n' > "$site/index.html"
printf 'p { color: black; }\n' > "$site/sub/a.css"
printf 'throughstone.org\n' > "$pages/CNAME"
: > "$pages/.nojekyll"
printf '<p>stale</p>\n' > "$pages/OLD.html"
printf 'p { color: red; }\n' > "$pages/sub/OLD.css"

set +e
publish_out="$("$TMP_ROOT/brand/publish-site.sh" 2>&1)"
publish_status=$?
set -e

[ "$publish_status" -eq 0 ] || {
  printf 'FAIL: publishing the fixture site exited %s\n%s\n' "$publish_status" "$publish_out" >&2
  exit 1
}
printf '%s\n' "$publish_out" | grep -Fxq 'site publish check: PASS' || {
  printf 'FAIL: publishing did not verify what it wrote\n%s\n' "$publish_out" >&2
  exit 1
}
for rel in index.html sub/a.css; do
  cmp -s "$site/$rel" "$pages/$rel" || {
    printf 'FAIL: publishing did not copy brand/site/%s to docs/%s\n' "$rel" "$rel" >&2
    exit 1
  }
done
for rel in OLD.html sub/OLD.css; do
  [ ! -e "$pages/$rel" ] || {
    printf 'FAIL: publishing left docs/%s, which brand/site/ does not have\n' "$rel" >&2
    exit 1
  }
done
grep -Fxq 'throughstone.org' "$pages/CNAME" || {
  printf 'FAIL: publishing did not keep docs/CNAME\n' >&2
  exit 1
}
[ -f "$pages/.nojekyll" ] || {
  printf 'FAIL: publishing did not keep docs/.nojekyll\n' >&2
  exit 1
}

echo "site-publish.sh: PASS"
