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
# license claim over code the method did not author. It looks wherever METHOD.md §7 says licensing
# lives — root files, nested trees, package metadata — but it can only catch a repo that SAYS
# something. METHOD.md §7 counts "a deliberate absence" as a licensing status too, and a repo that
# states nothing is indistinguishable from one just created. So this is a backstop against a
# misdirected invocation, not the control: the rule that this is run only on a repo the method
# creates is the control, and where that is unclear the answer is to ask (METHOD.md §7).
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

# find_pre_existing_licensing TARGET — list evidence that TARGET already states its own licensing.
# Reads: TARGET's root entries, its nested trees, and its root package metadata.
# Writes: nothing (prints one path per line).
# Returns: 0 always; empty output means the target says nothing about its licensing.
#
# A repo the method creates carries none of this, so it is inert on the path the helper is for. A
# repo that predates the method may carry any of it, and it looks in three places because that is
# where METHOD.md §7, the repo README template, and the recon map template all tell an agent to
# read: "a LICENSE, a COPYING, a NOTICE, package metadata, vendored third-party terms".
#
#   1. Root filenames — COPYING for a GPL project, NOTICE for attribution obligations,
#      LICENSE.md / LICENSE-<id> for the many projects that name the file differently.
#   2. The same names further down — a monorepo licenses per package (packages/*/LICENSE), and a
#      vendored tree carries the terms it arrived under. Depth-limited and pruned of the
#      directories that hold installed dependencies rather than the repo's own code.
#   3. Any mention of licensing in root package metadata. Plenty of repos state their license
#      only there, in whatever shape their ecosystem uses — a key, a nested block, a keyword
#      argument — so this matches the word rather than a shape, and over-refuses by design.
#
# Plain root LICENSE is deliberately still not listed: verify_compatible already rejects a
# differing one, and an identical one is this helper's own idempotent re-run.
#
# It answers "does this repo say anything about its licensing", never "which license" — a backstop
# for an invocation the prose already forbids, not a detector. Anything it reports is a refusal,
# so it errs toward refusing: being wrong here costs a question, and being wrong the other way
# writes a license claim over code the method did not author.
find_pre_existing_licensing() {
  local target="$1"
  {
    find "$target" -mindepth 1 -maxdepth 1 \
      \( -iname 'COPYING*' -o -iname 'COPYRIGHT*' -o -iname 'NOTICE*' \
         -o -iname 'LICENCE*' -o -iname 'LICENSE.*' -o -iname 'LICENSE-*' \
         -o -iname 'LICENSES' \) \
      ! -name 'LICENSE-THROUGHSTONE' \
      -print 2>/dev/null

    # Nested licensing. -prune drops installed dependency trees — those are somebody else's copies
    # rather than a statement about this repo, and a repo the method DID create can be carrying
    # them by the time this runs. It keeps deliberately vendored source trees, which are exactly
    # the "vendored third-party terms" METHOD.md §7 names. The prune must be able to see a
    # directory to skip it, so this find starts at the root and the root's own files are dropped
    # afterwards (they belong to the first find, which deliberately ignores a plain LICENSE).
    find "$target" -maxdepth 4 \
      \( -name '.git' -o -name 'node_modules' -o -name '.venv' -o -name 'venv' \
         -o -name 'site-packages' -o -name 'target' -o -path '*/vendor/bundle' \) -prune \
      -o \( -iname 'COPYING' -o -iname 'COPYING.*' -o -iname 'LICENSE' -o -iname 'LICENCE' \
            -o -iname 'LICENSE.*' -o -iname 'LICENCE.*' \) \
         ! -name 'LICENSE-THROUGHSTONE' -print 2>/dev/null \
      | while IFS= read -r found; do
          [ "$(dirname "$found")" = "$target" ] || printf '%s\n' "$found"
        done

    # Any mention of licensing in root package metadata. This matches the bare word, not a
    # key/value shape, and that is deliberate.
    #
    # Matching on shape asks a manifest for something it is under no obligation to have. Gradle
    # states a license as a nested block (`licenses { license { name "Apache-2.0" } }`) with no
    # separator to key on; setup.py states it as a keyword argument. Both were measured taking a
    # project LICENSE over their own terms while a pattern that wanted `license = value` looked
    # straight past them. Every shape invented later would need another pattern, and the failure
    # is silent: the repo is served, and a license claim lands on code the method did not write.
    #
    # So the question is "does this file mention licensing at all", and anything found is a
    # refusal. That over-refuses on purpose. A manifest whose license field is empty, one naming
    # a `licenseFile` instead of a license, and a repo that merely depends on a license-scanning
    # tool all refuse now. Each costs one question to someone who can look at their own manifest
    # and say there is nothing there. The other direction asks nobody anything and writes a
    # license over somebody else's work.
    local manifest
    for manifest in "$target"/package.json "$target"/pyproject.toml "$target"/setup.cfg \
                    "$target"/setup.py "$target"/Cargo.toml "$target"/composer.json \
                    "$target"/*.gemspec "$target"/build.gradle "$target"/build.gradle.kts \
                    "$target"/pom.xml; do
      [ -f "$manifest" ] || continue
      if grep -Eiq 'licen[cs]e' "$manifest" 2>/dev/null; then
        printf '%s\n' "$manifest"
      fi
    done
  } | LC_ALL=C sort -u
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
  Unset)
    # A project that adopted an existing codebase defers the license question to the recon-map
    # checkpoint, where the repos' own licensing is on the table to answer it from. Reaching here
    # means a repo is being scaffolded before that happened — so say which question is unanswered
    # and where it gets answered, rather than failing as though the file were corrupt.
    echo "apply-project-license.sh: this project has not chosen its license yet." >&2
    echo "        Adoption defers the question to the recon-map checkpoint, which answers it with" >&2
    echo "        scripts/set-project-license.sh. Run that first; this helper stamps the answer." >&2
    echo "        Nothing was written." >&2
    exit 1
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
