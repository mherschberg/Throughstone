#!/usr/bin/env bash
#
# apply-project-license.sh TARGET_REPO — apply the bootstrap-selected project-license posture.
#
# The posture file is the durable source of truth, separate from LICENSE, so a missing or
# extra license file cannot silently change whether the generated project is open-source or
# proprietary. This helper is for newly scaffolded application-code repos that retain
# Throughstone-authored README / CI material.

set -euo pipefail

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization; derive the docs hub without resolving
# the placeholder in this template checkout.
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

# verify_compatible SOURCE TARGET LABEL — reject an existing target with different content.
# Reads: SOURCE and TARGET, if TARGET exists.
# Writes: nothing.
# Returns: 0 when TARGET is absent or byte-identical; non-zero when it would be overwritten.
verify_compatible() {
  local source="$1" target="$2" label="$3"
  if [ -e "$target" ] && ! cmp -s "$source" "$target"; then
    echo "apply-project-license.sh: refusing to overwrite different $label: $target" >&2
    return 1
  fi
}

# copy_if_missing SOURCE TARGET LABEL — copy a prepared file only when TARGET is absent.
# Reads: SOURCE and TARGET metadata.
# Writes: TARGET when it does not already exist.
# Returns: 0 when TARGET exists or the copy succeeds; non-zero on cp failure.
copy_if_missing() {
  local source="$1" target="$2" label="$3"
  if [ -e "$target" ]; then
    echo "$label: $target (already current)"
  else
    cp "$source" "$target"
    echo "$label: $target"
  fi
}

# The posture file is written during bootstrap and must contain one of the supported
# project-license IDs. It decides the licensing path; LICENSE files are validated against it,
# not treated as the authority.
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

# Generated repos keep Throughstone-authored scaffold material, so they need the Throughstone
# notice even when the project's own code is proprietary or uses a different open-source license.
if [ ! -f "$DOCS_ROOT/LICENSE-THROUGHSTONE" ]; then
  echo "apply-project-license.sh: missing Throughstone notice: $DOCS_ROOT/LICENSE-THROUGHSTONE" >&2
  exit 1
fi
verify_compatible \
  "$DOCS_ROOT/LICENSE-THROUGHSTONE" \
  "$TARGET/LICENSE-THROUGHSTONE" \
  "Throughstone license"

# Open-source projects copy the docs hub's canonical project LICENSE unchanged. Proprietary
# projects intentionally have no project LICENSE in the docs hub or generated repo.
if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ] && [ ! -f "$DOCS_ROOT/LICENSE" ]; then
  echo "apply-project-license.sh: project posture is $PROJECT_LICENSE_ID, but the canonical license is missing: $DOCS_ROOT/LICENSE" >&2
  exit 1
fi
if [ "$PROJECT_IS_OPEN_SOURCE" = "0" ] && [ -e "$DOCS_ROOT/LICENSE" ]; then
  echo "apply-project-license.sh: project posture is Proprietary, but the docs hub has a project LICENSE: $DOCS_ROOT/LICENSE" >&2
  exit 1
fi

# LICENSING.md is generated from the same posture so each repo states both scopes explicitly:
# project-authored content and retained Throughstone scaffold material.
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

# Validate every existing target file before writing into the target repo. This preserves the
# no-overwrite compatibility invariant and avoids partially updating a repo with conflicting
# license state.
if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  verify_compatible "$DOCS_ROOT/LICENSE" "$TARGET/LICENSE" "project license"
elif [ -e "$TARGET/LICENSE" ]; then
  echo "apply-project-license.sh: project is proprietary, but target already has LICENSE: $TARGET/LICENSE" >&2
  exit 1
fi

# Write only missing, already-validated files. LICENSE-THROUGHSTONE documents the scaffold's
# license; LICENSING.md explains why that notice coexists with the project license posture.
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
