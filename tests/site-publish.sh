#!/usr/bin/env bash
#
# Regression coverage for the brand/site -> docs GitHub Pages publish contract.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/brand/publish-site.sh" --check

grep -Fxq 'throughstone.org' "$ROOT/docs/CNAME" || {
  printf 'FAIL: docs/CNAME must contain throughstone.org\n' >&2
  exit 1
}

[ -f "$ROOT/docs/.nojekyll" ] || {
  printf 'FAIL: docs/.nojekyll is missing\n' >&2
  exit 1
}

echo "site-publish.sh: PASS"
