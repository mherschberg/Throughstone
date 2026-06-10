#!/usr/bin/env bash
#
# Apply the project-license posture selected during Throughstone bootstrap.

set -euo pipefail

DOCS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"
POLICY_FILE="$DOCS_ROOT/.throughstone/project-license"

if [ -z "$TARGET" ]; then
  echo "usage: $0 TARGET_REPO" >&2
  exit 2
fi
if [ ! -d "$TARGET" ]; then
  echo "apply-project-license.sh: target directory does not exist: $TARGET" >&2
  exit 2
fi

verify_compatible() {
  local source="$1" target="$2" label="$3"
  if [ -e "$target" ] && ! cmp -s "$source" "$target"; then
    echo "apply-project-license.sh: refusing to overwrite different $label: $target" >&2
    return 1
  fi
}

copy_if_missing() {
  local source="$1" target="$2" label="$3"
  if [ -e "$target" ]; then
    echo "$label: $target (already current)"
  else
    cp "$source" "$target"
    echo "$label: $target"
  fi
}

if [ ! -f "$POLICY_FILE" ]; then
  echo "apply-project-license.sh: missing project-license posture: $POLICY_FILE" >&2
  exit 1
fi
PROJECT_LICENSE_ID="$(cat "$POLICY_FILE")"
case "$PROJECT_LICENSE_ID" in
  MIT|BSD-3-Clause|Apache-2.0)
    PROJECT_IS_OPEN_SOURCE=1
    ;;
  Proprietary)
    PROJECT_IS_OPEN_SOURCE=0
    ;;
  *)
    echo "apply-project-license.sh: invalid project-license posture in $POLICY_FILE: $PROJECT_LICENSE_ID" >&2
    exit 1
    ;;
esac

if [ ! -f "$DOCS_ROOT/LICENSE-THROUGHSTONE" ]; then
  echo "apply-project-license.sh: missing Throughstone notice: $DOCS_ROOT/LICENSE-THROUGHSTONE" >&2
  exit 1
fi
verify_compatible \
  "$DOCS_ROOT/LICENSE-THROUGHSTONE" \
  "$TARGET/LICENSE-THROUGHSTONE" \
  "Throughstone license"

if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ] && [ ! -f "$DOCS_ROOT/LICENSE" ]; then
  echo "apply-project-license.sh: project posture is $PROJECT_LICENSE_ID, but the canonical license is missing: $DOCS_ROOT/LICENSE" >&2
  exit 1
fi
if [ "$PROJECT_IS_OPEN_SOURCE" = "0" ] && [ -e "$DOCS_ROOT/LICENSE" ]; then
  echo "apply-project-license.sh: project posture is Proprietary, but the docs hub has a project LICENSE: $DOCS_ROOT/LICENSE" >&2
  exit 1
fi

LICENSING_SOURCE="$(mktemp "${TMPDIR:-/tmp}/throughstone-licensing.XXXXXX")"
trap 'rm -f "$LICENSING_SOURCE"' EXIT
if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  cat > "$LICENSING_SOURCE" <<EOF
# Licensing

Project-authored content in this repository is licensed under $PROJECT_LICENSE_ID. See
\`LICENSE\` for the full project license.

\`LICENSE-THROUGHSTONE\` applies only to retained Throughstone-authored scaffold material;
it does not replace or alter the project license.
EOF
else
  cat > "$LICENSING_SOURCE" <<'EOF'
# Licensing

Project-authored content in this repository is proprietary. No project `LICENSE` is
provided, and the presence of `LICENSE-THROUGHSTONE` does not grant permission to copy,
modify, or distribute the project's application code.

`LICENSE-THROUGHSTONE` applies only to retained Throughstone-authored scaffold material.
EOF
fi
verify_compatible "$LICENSING_SOURCE" "$TARGET/LICENSING.md" "licensing summary"

if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  verify_compatible "$DOCS_ROOT/LICENSE" "$TARGET/LICENSE" "project license"
elif [ -e "$TARGET/LICENSE" ]; then
  echo "apply-project-license.sh: project is proprietary, but target already has LICENSE: $TARGET/LICENSE" >&2
  exit 1
fi

copy_if_missing \
  "$DOCS_ROOT/LICENSE-THROUGHSTONE" \
  "$TARGET/LICENSE-THROUGHSTONE" \
  "Throughstone license"
copy_if_missing "$LICENSING_SOURCE" "$TARGET/LICENSING.md" "licensing summary"

if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  copy_if_missing "$DOCS_ROOT/LICENSE" "$TARGET/LICENSE" "project license"
else
  echo "project license: proprietary (no LICENSE created)"
fi
