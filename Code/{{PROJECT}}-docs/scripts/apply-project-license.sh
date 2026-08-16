#!/usr/bin/env bash
#
# apply-project-license.sh [--notice-only] TARGET_REPO — apply the bootstrap-selected
# project-license posture, or place only the Throughstone notice.
#
# The posture file is the durable source of truth, separate from LICENSE, so a missing or
# extra license file cannot silently change whether the generated project is open-source or
# proprietary. It records the license for THROUGHSTONE-AUTHORED AND METHOD-CREATED material —
# the docs hub, prompts/, and any repo the method creates — not for code the method did not
# write. This helper is for newly scaffolded application-code repos that retain
# Throughstone-authored README / CI material.
#
# It applies only to a repo the method CREATES. A repo that existed before the method reached it
# — registered in place by its registries/repos.yml `location:` — already has an owner and a
# licensing status, and setting a license for it is that owner's act, not the method's: read what
# it already uses and record it, never apply. The pre-existing-licensing check below refuses such
# a target, so pointing this helper at the wrong kind of repo fails loudly instead of writing a
# license claim over code the method did not author.
#
# --notice-only serves the one thing such a repo may still be owed. Where the method leaves
# Throughstone-authored material behind — a role-and-place section added to an existing README, or
# a README written from the template for a repo that had none — that material is BSD-3-Clause and
# needs its notice. This mode places LICENSE-THROUGHSTONE and a LICENSING.md that names only what
# the notice covers and disclaims everything else. It writes no project LICENSE and makes no claim
# about the repository's own code, which is why it is allowed on a repo the full mode refuses.

set -euo pipefail

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization; derive the docs hub without resolving
# the placeholder in this template checkout.
DOCS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_FILE="$DOCS_ROOT/.throughstone/project-license"

# Flags before or after the target, so callers need not remember an order.
TARGET=""
NOTICE_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --notice-only) NOTICE_ONLY=1 ;;
    -*)
      echo "apply-project-license.sh: unknown option: $1" >&2
      echo "usage: $0 [--notice-only] TARGET_REPO" >&2
      exit 2
      ;;
    *)
      if [ -n "$TARGET" ]; then
        echo "apply-project-license.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      TARGET="$1"
      ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  echo "usage: $0 [--notice-only] TARGET_REPO" >&2
  exit 2
fi
if [ ! -d "$TARGET" ]; then
  echo "apply-project-license.sh: target directory does not exist: $TARGET" >&2
  exit 2
fi

# find_pre_existing_licensing TARGET — list root-level licensing files this helper never writes.
# Reads: TARGET's root directory entries.
# Writes: nothing (prints one path per line).
# Returns: 0 always; empty output means the target carries no such file.
#
# A repo the method creates carries none of these, so this is inert on the path the helper is
# for. A repo that predates the method may carry any of them — COPYING for a GPL project, NOTICE
# for a project with attribution obligations, LICENSE.md/LICENSE-<id> for the many projects that
# name the file differently. Plain LICENSE is deliberately not listed: verify_compatible already
# rejects a differing one, and an identical one is this helper's own idempotent re-run.
find_pre_existing_licensing() {
  find "$1" -mindepth 1 -maxdepth 1 \
    \( -iname 'COPYING*' -o -iname 'COPYRIGHT*' -o -iname 'NOTICE*' \
       -o -iname 'LICENCE*' -o -iname 'LICENSE.*' -o -iname 'LICENSE-*' \
       -o -iname 'LICENSES' \) \
    ! -name 'LICENSE-THROUGHSTONE' \
    -print 2>/dev/null | LC_ALL=C sort
}

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

# --notice-only stops here. It never reads the posture, never writes a project LICENSE, and is
# therefore allowed on a repo that states its own terms — the case the guard below exists to
# refuse. Its LICENSING.md is deliberately not the one the full mode writes: that one names the
# project license and asserts it over the repository's content, which would be a claim about code
# the method did not author.
if [ "$NOTICE_ONLY" = "1" ]; then
  if [ ! -f "$DOCS_ROOT/LICENSE-THROUGHSTONE" ]; then
    echo "apply-project-license.sh: missing Throughstone notice: $DOCS_ROOT/LICENSE-THROUGHSTONE" >&2
    exit 1
  fi
  NOTICE_SUMMARY="$(mktemp "${TMPDIR:-/tmp}/throughstone-notice.XXXXXX")"
  trap 'rm -f "$NOTICE_SUMMARY"' EXIT
  cat > "$NOTICE_SUMMARY" <<'EOF'
# Licensing

This repository was not created by Throughstone; a project that uses Throughstone registered it
in place. `LICENSE-THROUGHSTONE` covers **only** the Throughstone-authored scaffold material
retained here — for example a role-and-place section added to the README.

It does not license, alter, or make any claim about anything else in this repository. Everything
else remains under this repository's own terms, wherever they are stated.
EOF
  # Validate both targets before writing either, so a repo is never left half-updated.
  verify_compatible \
    "$DOCS_ROOT/LICENSE-THROUGHSTONE" \
    "$TARGET/LICENSE-THROUGHSTONE" \
    "Throughstone license"
  verify_compatible "$NOTICE_SUMMARY" "$TARGET/LICENSING.md" "licensing summary"
  copy_if_missing \
    "$DOCS_ROOT/LICENSE-THROUGHSTONE" \
    "$TARGET/LICENSE-THROUGHSTONE" \
    "Throughstone license"
  copy_if_missing "$NOTICE_SUMMARY" "$TARGET/LICENSING.md" "licensing summary"
  echo "project license: not applied (--notice-only; this repository's licensing is its own)"
  exit 0
fi

# Refuse a repo that already states its own licensing, before reading the posture or writing
# anything. This is the guard against the destructive case: a target with no plain LICENSE but a
# COPYING or NOTICE would otherwise take the project's LICENSE and a LICENSING.md asserting that
# license over the whole repository — a claim about code the method did not write.
PRE_EXISTING_LICENSING="$(find_pre_existing_licensing "$TARGET")"
if [ -n "$PRE_EXISTING_LICENSING" ]; then
  echo "apply-project-license.sh: target already states its own licensing:" >&2
  printf '%s\n' "$PRE_EXISTING_LICENSING" | while IFS= read -r found; do
    echo "  $found" >&2
  done
  echo "apply-project-license.sh: this helper applies the project posture to repos this method" >&2
  echo "        creates. A repo that already existed keeps the licensing its owner set — record" >&2
  echo "        what it uses (in the repo inventory and its architecture docs) rather than" >&2
  echo "        applying a license to it. Nothing was written." >&2
  exit 1
fi

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
