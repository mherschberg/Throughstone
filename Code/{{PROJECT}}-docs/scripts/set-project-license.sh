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

# is_generated_repo DIR — true when DIR is a repo init.sh created, rather than a folder inside one.
# Reads: DIR's git metadata.
# Writes: nothing.
# Returns: 0 when DIR is the top level of its own work tree.
#
# This is what tells the layouts apart without being told which one is in use. Multi-repo makes the
# docs hub and prompts/ their own repos and leaves the workspace root a plain shell; mono-repo makes
# the root the one repo, so the docs hub inside it reports the root as its top level, not itself.
# Both sides are compared as PHYSICAL paths: `git rev-parse --show-toplevel` resolves symlinks,
# and a logical `pwd` does not, so on a system whose temp or home path is a symlink the two never
# match and every repo looks like a folder inside another one.
is_generated_repo() {
  local top
  top="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 1
  top="$(cd "$top" 2>/dev/null && pwd -P)" || return 1
  [ "$top" = "$(cd "$1" && pwd -P)" ]
}

# generated_repos — print each generated repo this answer should settle.
# Reads: the docs hub, its sibling prompts/, and the workspace root.
# Writes: nothing (prints one path per line).
# Returns: 0 always.
#
# Those three are every directory init.sh can turn into a generated repo. Selection used to key on
# the deferred marker inside LICENSING.md, which silently skipped any repo whose copy had been
# edited or deleted: the posture was written, the inventory rewritten, and that repo was left with
# no LICENSE and no mention of it — unrecoverable afterwards, since a second run is refused as an
# answer already given and apply-project-license.sh refuses a target whose LICENSING.md differs.
#
# So membership is decided by what the directory IS, and the state of its LICENSING.md decides what
# happens to it: a missing one is written (a generated repo is owed it either way), a deferred one
# is replaced, and one that is neither is left alone and reported by unsettled_repos below. A repo
# is never skipped without saying so.
generated_repos() {
  local dir
  for dir in "$DOCS_ROOT" "$DOCS_ROOT/../../prompts" "$DOCS_ROOT/../.."; do
    [ -d "$dir" ] || continue
    is_generated_repo "$dir" || continue
    if [ -f "$dir/LICENSING.md" ] && ! grep -Fq "$DEFERRED_MARKER" "$dir/LICENSING.md"; then
      settled_licensing_matches "$dir" || continue
    fi
    ( cd "$dir" && pwd -P )
  done
}

# settled_licensing_matches DIR — true when DIR/LICENSING.md is already the summary this answer
# would write, i.e. a re-run rather than something a person edited.
# Reads: DIR/LICENSING.md, PROJECT_LICENSE_ID, PROJECT_IS_OPEN_SOURCE.
# Writes: a temp file, removed before returning.
# Returns: 0 when the existing file is byte-identical to the settled form.
settled_licensing_matches() {
  local probe rc
  probe="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-probe.XXXXXX")"
  write_licensing_summary "$probe"
  cmp -s "$probe/LICENSING.md" "$1/LICENSING.md"; rc=$?
  rm -rf "$probe"
  return "$rc"
}

# unsettled_repos — print each generated repo this answer must not touch and did not settle.
# Reads: the same three candidates.
# Writes: nothing (prints one path per line).
# Returns: 0 always.
#
# Only one case reaches here: a generated repo whose LICENSING.md is neither the deferred text nor
# the settled one, which means somebody wrote it. Overwriting it would destroy that; saying nothing
# is what this whole change exists to stop.
unsettled_repos() {
  local dir
  for dir in "$DOCS_ROOT" "$DOCS_ROOT/../../prompts" "$DOCS_ROOT/../.."; do
    [ -d "$dir" ] || continue
    is_generated_repo "$dir" || continue
    [ -f "$dir/LICENSING.md" ] || continue
    grep -Fq "$DEFERRED_MARKER" "$dir/LICENSING.md" && continue
    settled_licensing_matches "$dir" && continue
    ( cd "$dir" && pwd -P )
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

# A generated repo whose LICENSING.md somebody rewrote is the one thing this cannot settle without
# destroying their text. It is reported rather than skipped, because the answer has now been given
# and cannot be given again — leaving a repo out of it quietly is how one ends up with no LICENSE
# and nothing recording that.
UNSETTLED="$(unsettled_repos)"
if [ -n "$UNSETTLED" ]; then
  echo "" >&2
  echo "set-project-license.sh: these generated repos were NOT settled — their LICENSING.md has" >&2
  echo "        been edited, and overwriting it would discard what someone wrote there:" >&2
  printf '%s\n' "$UNSETTLED" | while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    echo "  $repo/LICENSING.md" >&2
  done
  echo "        The project's license is now $PROJECT_LICENSE_ID and this helper answers once, so" >&2
  echo "        re-running will not pick them up. Bring each into line by hand: state" >&2
  echo "        $PROJECT_LICENSE_ID in that file, and for an open-source posture copy" >&2
  echo "        $DOCS_ROOT/LICENSE to the repo root." >&2
fi

echo "Commit these changes in each repo they touched."
