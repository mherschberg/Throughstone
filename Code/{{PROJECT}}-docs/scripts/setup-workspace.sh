#!/usr/bin/env bash
#
# setup-workspace.sh — set up a NEW developer's machine for an existing project.
#
# The first developer ran init.sh to create the project. Everyone after runs this to
# assemble the workspace shell on their machine: clone the sibling repos and write the
# per-machine pointer files (CLAUDE.md / AGENTS.md) that the workspace root needs.
#
# Multi-repo projects only. A mono-repo-for-now project (METHOD.md §7) is a single repo with
# the pointers committed inside it — just clone that repo; there's nothing to assemble here.
#
# Usage:
#   1. Clone the docs repo first, into  <workspace>/Code/<project>-docs/
#   2. From the workspace root, run:    Code/<project>-docs/scripts/setup-workspace.sh
#
set -euo pipefail

# This script lives in Code/{{PROJECT}}-docs/scripts/ in the scaffold and in
# Code/<project>-docs/scripts/ after initialization; derive paths instead of hard-coding the
# generated project name. DOCS_REL is written into root pointers and falls back when python3
# is unavailable.
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"
DOCS_REL="$(python3 -c "import os;print(os.path.relpath('$DOCS_DIR','$ROOT'))" 2>/dev/null || echo "Code/$(basename "$DOCS_DIR")")"
cd "$ROOT"

echo "Workspace root: $ROOT"
echo "Docs hub:       $DOCS_REL"

# --- 1. Clone sibling repos listed in the registry (if it has remotes) ------
REG="$DOCS_DIR/registries/repos.yml"
if [ -f "$REG" ]; then
  echo "Cloning sibling repos with remotes from registries/repos.yml ..."
  # Parse repos.yml block-aware: pair each repo's own location with its own remote.
  # The registry is the multi-repo inventory, and remote: is optional. Walking each `- name:`
  # block keeps locations and remotes aligned when only some repos are cloneable; comment lines
  # and remote-less repos are skipped.
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*-[[:space:]]*name:/ { if (loc != "" && rem != "") print loc "|" rem; loc=""; rem=""; next }
    /^[[:space:]]*location:/ { loc=$0; sub(/^[^:]*:[[:space:]]*"?/,"",loc); sub(/"?[[:space:]]*$/,"",loc) }
    /^[[:space:]]*remote:/   { rem=$0; sub(/^[^:]*:[[:space:]]*"?/,"",rem); sub(/"?[[:space:]]*$/,"",rem) }
    END { if (loc != "" && rem != "") print loc "|" rem }
  ' "$REG" \
  | while IFS='|' read -r loc rem; do
      [ -n "${rem:-}" ] || continue
      # Clone side effect: create a missing sibling repo at its registry location. Existing git
      # checkouts are left untouched so rerunning setup is safe for already-cloned repos.
      [ -d "$loc/.git" ] && { echo "  exists: $loc"; continue; }
      echo "  cloning $rem -> $loc"
      git clone -q "$rem" "$loc"
    done
else
  echo "No registries/repos.yml — skipping clone step."
fi

# --- 2. Write the per-machine root pointers ---------------------------------
echo "Writing per-machine pointers (CLAUDE.md, AGENTS.md) ..."
# The workspace root is a per-machine shell in multi-repo projects, not a durable repo. These
# pointers are regenerated locally so agents opened at the root can find the canonical docs hub.
for name in CLAUDE.md AGENTS.md; do
  cat > "$ROOT/$name" <<EOF
# $name

The canonical agent context lives in the docs repo:
**\`$DOCS_REL/AGENTS.md\`** (tool-agnostic). Read it — and the methodology it points to in
\`$DOCS_REL/METHOD.md\` — before working here.

This is a per-machine pointer (the workspace root is not a repo). Edit the canonical file
in the docs repo, not this one.
EOF
done

mkdir -p "$ROOT/.claude"
echo "Done. Open this folder in your agent; it will discover the context via the pointers."
