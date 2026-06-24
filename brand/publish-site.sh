#!/usr/bin/env bash
#
# Publish the canonical site source in brand/site/ to the GitHub Pages output in docs/.

set -euo pipefail
export LC_ALL=C

BRAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$BRAND_DIR/.." && pwd)"
SRC="$ROOT/brand/site"
DEST="$ROOT/docs"

usage() {
  cat <<'USAGE'
Usage: brand/publish-site.sh [--check]

Copies brand/site/ into docs/ for GitHub Pages, preserving docs/CNAME and
docs/.nojekyll. With --check, reports whether docs/ is current without writing.
USAGE
}

mode="publish"
case "${1:-}" in
  "")
    ;;
  --check)
    mode="check"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

require_pages_files() {
  if [ ! -f "$DEST/CNAME" ]; then
    printf 'ERROR: %s is missing; Throughstone.org relies on this GitHub Pages CNAME file.\n' "$DEST/CNAME" >&2
    return 1
  fi
  if ! grep -Fxq 'throughstone.org' "$DEST/CNAME"; then
    printf 'ERROR: %s must contain throughstone.org for the custom domain.\n' "$DEST/CNAME" >&2
    return 1
  fi
  if [ ! -f "$DEST/.nojekyll" ]; then
    printf 'ERROR: %s is missing; GitHub Pages should bypass Jekyll for this static site.\n' "$DEST/.nojekyll" >&2
    return 1
  fi
}

list_site_files() {
  local dir="$1"
  (
    cd "$dir"
    find . -type f \
      ! -path './CNAME' \
      ! -path './.nojekyll' \
      | sed 's#^\./##' \
      | sort
  )
}

check_current() {
  require_pages_files

  local src_list dest_list status rel
  src_list="$(mktemp "${TMPDIR:-/tmp}/throughstone-site-src.XXXXXX")"
  dest_list="$(mktemp "${TMPDIR:-/tmp}/throughstone-site-dest.XXXXXX")"

  list_site_files "$SRC" > "$src_list"
  list_site_files "$DEST" > "$dest_list"

  status=0
  if ! diff -u "$src_list" "$dest_list"; then
    printf 'ERROR: docs/ file list differs from brand/site/. Run brand/publish-site.sh.\n' >&2
    status=1
  fi

  while IFS= read -r rel; do
    if [ -f "$DEST/$rel" ] && ! cmp -s "$SRC/$rel" "$DEST/$rel"; then
      printf 'ERROR: docs/%s differs from brand/site/%s. Run brand/publish-site.sh.\n' "$rel" "$rel" >&2
      status=1
    fi
  done < "$src_list"

  if [ "$status" -eq 0 ]; then
    printf 'site publish check: PASS\n'
  fi
  rm -f "$src_list" "$dest_list"
  return "$status"
}

publish_site() {
  mkdir -p "$DEST"
  require_pages_files

  find "$DEST" -mindepth 1 -maxdepth 1 \
    ! -name CNAME \
    ! -name .nojekyll \
    -exec rm -rf {} +

  find "$SRC" -mindepth 1 -maxdepth 1 \
    -exec cp -R {} "$DEST"/ \;

  check_current
}

if [ "$mode" = "check" ]; then
  check_current
else
  publish_site
fi
