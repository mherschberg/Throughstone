#!/usr/bin/env bash
#
# set-project-license.sh LICENSE [--holder NAME] — answer the project-license question once,
# after the codebase has been read.
#
# A project that adopts an existing codebase does not choose its license at install time. Nobody
# has read the repos yet at that point, and the repos themselves already carry the answer, so
# `init.sh --mode=existing` leaves `.throughstone/project-license` holding `Unset` and the
# adoption flow puts the question at the recon-map checkpoint instead — with each repo's licensing
# recorded in front of the user and what was found as the default. This helper is what that
# checkpoint runs. It exists so answering the question is one command rather than five
# hand-edits that can each be half-done.
#
# What it covers is what the posture has always covered: THROUGHSTONE-AUTHORED AND METHOD-CREATED
# material — this docs hub, prompts/, and any repo the method creates later. It is not a statement
# about the adopted code, and it writes nothing into an adopted repo. Those repos keep the
# licensing their owners set; the recon map and the repo inventory record it.
#
# It is deliberately one-way. Answering a question nobody has answered yet is bookkeeping;
# CHANGING a license already in force is not — repos are stamped from it, LICENSING.md files
# assert it, and copies may already be published. So a posture that is anything other than `Unset`
# is left alone: re-running with the same answer is a no-op, and a different answer is refused
# with what to do instead.

set -euo pipefail

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization; derive the docs hub without resolving
# the placeholder in this template checkout.
DOCS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_FILE="$DOCS_ROOT/.throughstone/project-license"
REGISTRY="$DOCS_ROOT/registries/repos.yml"

# The first line of the LICENSING.md that init.sh writes for a deferred posture. Finding it is how
# this script locates the generated repos without needing to know the project's layout: exactly
# the directories that got the placeholder summary are the ones owed the settled one.
DEFERRED_MARKER="This project has not chosen its license yet."

usage() {
  cat >&2 <<'USAGE'
usage: set-project-license.sh LICENSE [--holder NAME]

  LICENSE   mit | bsd-3 | apache-2.0 | private
  --holder  Copyright holder (name or org) — required for an open-source license

Answers the deferred project-license question for a project that adopted an existing codebase.
Covers this docs hub and anything the method creates later, never the adopted code.
USAGE
}

LICENSE_IN=""
HOLDER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --holder) HOLDER="${2:-}"; shift ;;
    --holder=*) HOLDER="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "set-project-license.sh: unknown option: $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$LICENSE_IN" ]; then
        echo "set-project-license.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      LICENSE_IN="$1"
      ;;
  esac
  shift
done

if [ -z "$LICENSE_IN" ]; then
  usage
  exit 2
fi

# Same friendly tokens init.sh accepts for --license, so the two questions take the same answers.
LICENSE_TEMPLATE_NAME=""
case "$(printf '%s' "$LICENSE_IN" | tr '[:upper:]' '[:lower:]')" in
  mit)
    PROJECT_LICENSE_ID="MIT"; LICENSE_TEMPLATE_NAME="MIT.txt" ;;
  bsd-3|bsd-3-clause|bsd)
    PROJECT_LICENSE_ID="BSD-3-Clause"; LICENSE_TEMPLATE_NAME="BSD-3-Clause.txt" ;;
  apache-2.0|apache-2|apache)
    PROJECT_LICENSE_ID="Apache-2.0"; LICENSE_TEMPLATE_NAME="Apache-2.0.txt" ;;
  private|proprietary)
    PROJECT_LICENSE_ID="Proprietary" ;;
  *)
    echo "set-project-license.sh: invalid license '$LICENSE_IN' (mit | bsd-3 | apache-2.0 | private)." >&2
    exit 2 ;;
esac
PROJECT_IS_OPEN_SOURCE=0
[ -n "$LICENSE_TEMPLATE_NAME" ] && PROJECT_IS_OPEN_SOURCE=1

if [ ! -f "$POLICY_FILE" ]; then
  echo "set-project-license.sh: missing project-license posture: $POLICY_FILE" >&2
  echo "        This runs inside an initialized project; the posture file is written by init.sh." >&2
  exit 1
fi
CURRENT="$(cat "$POLICY_FILE")"

# Already answered. Same answer is a re-run and does nothing; a different one is a relicensing,
# which is the project owner's deliberate act across every repo already stamped — not a flag flip.
if [ "$CURRENT" != "Unset" ]; then
  if [ "$CURRENT" = "$PROJECT_LICENSE_ID" ]; then
    echo "project license: already $PROJECT_LICENSE_ID (nothing to do)"
    exit 0
  fi
  echo "set-project-license.sh: this project's license is already $CURRENT." >&2
  echo "        This helper answers the question once, for a project that deferred it; it does" >&2
  echo "        not relicense one. Changing $CURRENT to $PROJECT_LICENSE_ID means rewriting every" >&2
  echo "        repo stamped from it and every LICENSING.md asserting it, and any copy already" >&2
  echo "        published stays under $CURRENT. Do it deliberately, not through this script." >&2
  echo "        Nothing was written." >&2
  exit 1
fi

if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  if [ -z "$HOLDER" ]; then
    echo "set-project-license.sh: --holder is required for $PROJECT_LICENSE_ID (it goes in the copyright line)." >&2
    exit 2
  fi
  TEMPLATE="$DOCS_ROOT/templates/licenses/$LICENSE_TEMPLATE_NAME"
  if [ ! -f "$TEMPLATE" ]; then
    echo "set-project-license.sh: project license template is missing: $TEMPLATE" >&2
    exit 1
  fi
fi

# generated_repos — print each directory holding a LICENSING.md this project has not settled yet.
# Reads: the docs hub, its sibling prompts/, and the workspace root.
# Writes: nothing (prints one path per line).
# Returns: 0 always.
#
# Those three are every directory init.sh can turn into a generated repo: multi-repo makes the docs
# hub and prompts/ repos, mono-repo makes the workspace root one. Selecting by the marker rather
# than by layout means this stays correct whichever one the project used, and skips a directory
# that is not a generated repo — the marker is only ever written by init.sh's deferred path.
generated_repos() {
  local dir
  for dir in "$DOCS_ROOT" "$DOCS_ROOT/../../prompts" "$DOCS_ROOT/../.."; do
    [ -f "$dir/LICENSING.md" ] || continue
    grep -Fq "$DEFERRED_MARKER" "$dir/LICENSING.md" || continue
    ( cd "$dir" && pwd )
  done
}

# write_licensing_summary DIR — replace the deferred summary with the settled one.
# Reads: PROJECT_LICENSE_ID.
# Writes: DIR/LICENSING.md.
# Returns: 0.
#
# Identical wording to init.sh's, so a project that deferred the question ends up with the same
# file a project that answered it at install time would have.
write_licensing_summary() {
  if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
    cat > "$1/LICENSING.md" <<EOF
# Licensing

Project-authored content in this repository is licensed under $PROJECT_LICENSE_ID. See
\`LICENSE\` for the full project license.

\`LICENSE-THROUGHSTONE\` applies only to retained Throughstone-authored scaffold material;
it does not replace or alter the project license.
EOF
  else
    cat > "$1/LICENSING.md" <<'EOF'
# Licensing

Project-authored content in this repository is proprietary. No project `LICENSE` is
provided, and the presence of `LICENSE-THROUGHSTONE` does not grant permission to copy,
modify, or distribute the project's application code.

`LICENSE-THROUGHSTONE` applies only to retained Throughstone-authored scaffold material.
EOF
  fi
}

REPOS="$(generated_repos)"

# Render the license text once, then copy it, so every repo carries byte-identical terms and the
# docs hub's canonical copy is the same file apply-project-license.sh will hand to future repos.
if [ "$PROJECT_IS_OPEN_SOURCE" = "1" ]; then
  RENDERED="$(mktemp "${TMPDIR:-/tmp}/throughstone-license.XXXXXX")"
  trap 'rm -f "$RENDERED"' EXIT
  YEAR="$(date +%Y)" HOLDER="$HOLDER" perl -pe \
    's/\Q{{YEAR}}\E/$ENV{YEAR}/g; s/\Q{{HOLDER}}\E/$ENV{HOLDER}/g' \
    "$TEMPLATE" > "$RENDERED"
  # The docs hub always keeps the canonical copy, whether or not it is itself a generated repo:
  # apply-project-license.sh reads it from there for every repo the method creates later.
  cp "$RENDERED" "$DOCS_ROOT/LICENSE"
  echo "  canonical project license: $DOCS_ROOT/LICENSE"
  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    [ "$repo" = "$DOCS_ROOT" ] && continue
    cp "$RENDERED" "$repo/LICENSE"
    echo "  license: $repo/LICENSE"
  done <<EOF
$REPOS
EOF
fi

printf '%s\n' "$PROJECT_LICENSE_ID" > "$POLICY_FILE"
echo "  posture: $POLICY_FILE ($PROJECT_LICENSE_ID)"

# The inventory rows for the repos init.sh created carry the same `Unset` until now. Only that
# literal is replaced: a row recording an adopted repo's own licensing holds what that repo says,
# and must not be touched by an answer about this method's material.
if [ -f "$REGISTRY" ] && grep -Fq 'license: "Unset"' "$REGISTRY"; then
  PROJECT_LICENSE_ID="$PROJECT_LICENSE_ID" perl -pi -e \
    's/\Qlicense: "Unset"\E/license: "$ENV{PROJECT_LICENSE_ID}"/g' "$REGISTRY"
  echo "  repo inventory: $REGISTRY"
fi

while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  write_licensing_summary "$repo"
  echo "  licensing summary: $repo/LICENSING.md"
done <<EOF
$REPOS
EOF

if [ "$PROJECT_IS_OPEN_SOURCE" = "0" ]; then
  echo "project license: Proprietary (no LICENSE created)"
fi
echo "Commit these changes in each repo they touched."
