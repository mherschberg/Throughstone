#!/usr/bin/env bash
#
# setup-workspace.sh — set up a NEW developer's machine for an existing project.
#
# The first developer ran init.sh to create the project. Everyone after runs this to
# assemble the workspace shell on their machine: write the per-machine pointer/helper files
# (CLAUDE.md / AGENTS.md / doctor.sh) that the workspace root needs, and clone the sibling repos.
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

# --- 0. Refuse a mono-repo-for-now workspace ---------------------------------
# Mono (METHOD.md §7) is one repository, and the workspace root IS that repository. There the
# three files written below are committed rather than per-machine, and no row in the registry is
# a repo to clone. This script has declared itself multi-repo-only since it was written and then
# run anyway: in a mono clone it rewrote three tracked files with per-machine versions asserting
# the root is not a repo, said "Done", and left the contributor holding modifications they never
# made — which a `git add -A` would then commit for the whole team.
#
# The test is the one check.sh uses to decide whether a location is a repository, on physical
# paths both sides. In multi the workspace root is never a work-tree root; in mono it always is.
# A workspace that merely sits inside some other repository answers no, because the comparison is
# against this root rather than against any root.
#
# What the message may say is bounded by what was measured. This test reads the root and not the
# registry, so it knows the root is a repository and does not know the project is mono -- which is
# the overwhelmingly likely reason, and the only one the method supports, but a multi-repo
# workspace whose root somebody made a repository lands here too. Naming that reading is cheaper
# than reading the registry to rule it out, and it is the only way the contributor who is in it
# hears anything at all.
root_toplevel="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$root_toplevel" ] && [ "$root_toplevel" = "$(pwd -P)" ]; then
  echo
  echo "This workspace root is itself a git repository, so there is nothing here to assemble."
  echo "In a mono-repo-for-now project (METHOD.md section 7) that is the whole workspace: the root"
  echo "pointers are committed in that repository rather than written per machine, and the clone"
  echo "you already have is everything."
  echo
  echo "Nothing was written. If this was meant to be a multi-repo workspace, the root is not"
  echo "supposed to be a repository -- check where the docs hub was cloned."
  exit 0
fi

# --- 1. Write the per-machine root pointers/helpers --------------------------
# These are written before the clone step deliberately, but the ordering is not what makes the
# clone step safe — step 2 warns and continues instead of aborting, so it can no longer take the
# workspace down with it. The ordering is insurance against the *next* fatal path someone adds:
# whatever fails below, the contributor still ends up with AGENTS.md, CLAUDE.md and doctor.sh.
echo "Writing per-machine pointers and helpers (CLAUDE.md, AGENTS.md, doctor.sh) ..."
# The workspace root is a per-machine shell in multi-repo projects, not a durable repo. These
# pointers are regenerated locally so agents opened at the root can find the canonical docs hub.
#
# What they say has to match what init.sh leaves at the root for the person who created the
# project, because this is the file every contributor reads first and the handoff depends on it:
# the closing paragraph is what turns "Read AGENTS.md and follow it" into an instruction. Written
# thinner here, everyone who joined after the first person was missing it.
for name in CLAUDE.md AGENTS.md; do
  # The one clause that differs between the two files: each names the tool that reads it.
  case "$name" in
    CLAUDE.md) reader="Claude Code" ;;
    *)         reader="any agent (Codex, etc.)" ;;
  esac
  cat > "$ROOT/$name" <<EOF
# $name

The canonical agent context lives in the docs repo:
**\`$DOCS_REL/AGENTS.md\`** (tool-agnostic). Read it — and the methodology it points to in
\`$DOCS_REL/METHOD.md\` — before working here.

This is a per-machine pointer so $reader auto-discovers the project context. It is not
versioned (the workspace root is not a repo). Edit the canonical file in the docs repo, not
this one. \`$DOCS_REL/scripts/setup-workspace.sh\` regenerates this pointer on a new machine.

**Agents:** the canonical \`AGENTS.md\` (linked above) opens with a "First action — kickoff or
resume?" section. Read it and follow it now — it decides, from disk, whether to start the
kickoff interview (new project) or resume the next STEP (existing one). The user's whole
handoff is the single command *"Read AGENTS.md and follow it."*
EOF
done

cat > "$ROOT/doctor.sh" <<EOF
#!/usr/bin/env bash
#
# doctor.sh — root Throughstone doctor wrapper generated by setup-workspace.sh.

set -euo pipefail

ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="\$ROOT/$DOCS_REL/scripts/doctor.sh"

if [ ! -x "\$SCRIPT" ]; then
  echo "doctor.sh: dispatcher is missing or not executable: \$SCRIPT" >&2
  exit 1
fi

exec "\$SCRIPT" "\$@"
EOF
chmod +x "$ROOT/doctor.sh"

mkdir -p "$ROOT/.claude"
mkdir -p "$ROOT/.throughstone"

# --- 2. Clone sibling repos listed in the registry (if it has remotes) ------
# Nothing in this step is allowed to be fatal. A contributor who cannot reach one repository —
# or whose registry names a path this workspace has no business writing to — must still end up
# with a usable workspace, so every repo that does not arrive is reported and counted rather
# than aborting the run.
REG="$DOCS_DIR/registries/repos.yml"
missing=0
if [ -f "$REG" ]; then
  echo "Cloning sibling repos with remotes from registries/repos.yml ..."
  # Parse repos.yml block-aware: pair each repo's own location with its own remote.
  # The registry is the multi-repo inventory, and remote: is optional. Walking each `- name:`
  # block keeps locations and remotes aligned when only some repos are cloneable; comment lines
  # and remote-less repos are skipped.
  #
  # The loop is fed by process substitution rather than a pipe for two reasons: the parser's
  # exit status stays out of the pipeline, so a registry awk cannot read is not fatal either;
  # and the loop body runs in this shell rather than a subshell, so the count below survives it.
  while IFS='|' read -r loc rem; do
    [ -n "${rem:-}" ] || continue
    # Clone side effect: create a missing sibling repo at its registry location. Existing git
    # checkouts are left untouched so rerunning setup is safe for already-cloned repos. This
    # is also what leaves a repo registered in place alone: it is already where it belongs.
    # Left alone only if it really is a repository. A submodule and a linked worktree present .git
    # as a FILE rather than a directory, which is what made -d wrong; -e was wrong the other way,
    # because a .git file left behind by a worktree that was moved or deleted still exists and is
    # not a repository. Skipping on that cloned nothing and reported nothing, so the workspace was
    # quietly incomplete. Asking git is the test check.sh uses, on physical paths both sides.
    # Anything that fails it falls through to the clone below, which refuses over a non-empty
    # directory and counts the repo among those that did not arrive — loudly, which is the point.
    # And only if the repository is actually here. A work tree with no resolvable HEAD is the
    # shape a clone leaves when the remote HEAD names a branch nobody created: a .git directory
    # and no files. The doctor asks a different question of the same path -- is this a repository
    # whose contents a row can describe -- and an empty checkout has no contents to describe, so
    # the two are not meant to answer alike here. This one asks whether the contributor has the
    # repo, and they do not. Without it the clone below counts as arrived once and every re-run
    # after that says "exists", which is the silent half of the failure.
    if [ -d "$loc" ]; then
      loc_top="$(git -C "$loc" rev-parse --show-toplevel 2>/dev/null || true)"
      if [ -n "$loc_top" ] && [ "$loc_top" = "$(cd "$loc" && pwd -P)" ] \
         && git -C "$loc" rev-parse --verify -q HEAD >/dev/null 2>&1; then
        echo "  exists: $loc"
        continue
      fi
    fi
    # A location this workspace cannot own is referenced where it sits, never cloned into.
    # Cloning would put the repository outside the workspace this script is assembling —
    # silently, when the path happens to be writable. The test is textual on purpose: an
    # absolute path from the first developer's machine must be skipped whether or not it
    # resolves to anything here.
    case "$loc" in
      /* | .. | ../* | */../* | */..)
        echo "  skipped: $loc — outside the workspace root; this script never clones there"
        missing=$((missing + 1))
        continue
        ;;
    esac
    echo "  cloning $rem -> $loc"
    # Exit 0 from git clone is not a repository on disk. Cloning a remote whose HEAD names a
    # branch that does not exist there succeeds, warns, and leaves an empty working tree behind --
    # which is the same fixture bug 9d323b4 found in this suite, where every clone had been
    # arriving empty and the assertion could not tell. That commit taught the test what a clone
    # is and left this loop believing exit 0. A resolvable HEAD is the difference, and the two
    # failures are told apart because the remedies are not the same one.
    if ! git clone -q "$rem" "$loc"; then
      echo "  warning: could not clone $rem -> $loc — continuing without it"
      missing=$((missing + 1))
    elif ! git -C "$loc" rev-parse --verify -q HEAD >/dev/null 2>&1; then
      echo "  warning: $rem arrived at $loc with nothing checked out — its HEAD names a branch"
      echo "           that does not exist there. Fix the default branch on the remote, delete"
      echo "           $loc, and re-run."
      missing=$((missing + 1))
    fi
  done < <(awk '
    BEGIN { SQ = sprintf("%c", 39) }
    # This is the reading of a scalar scripts/check.sh uses, character for character. These two
    # fields are the ones this loop consumes verbatim, so a doctor that passed a value this loop
    # then read differently was the single failure neither script could report: the check said
    # the file was fine and the clone landed somewhere else. tests/ runs one table through both.
    function clean(v,   q, i, c, out, rest) {
      gsub(/\t/, " ", v)
      q = substr(v, 1, 1)
      if (q == "\"" || q == SQ) {
        out = ""
        i = 2
        while (i <= length(v)) {
          c = substr(v, i, 1)
          if (c == "\\" && q == "\"") { out = out substr(v, i + 1, 1); i = i + 2; continue }
          if (c == q) {
            if (q == SQ && substr(v, i + 1, 1) == SQ) { out = out q; i = i + 2; continue }
            break
          }
          out = out c
          i++
        }
        if (i <= length(v)) {
          rest = substr(v, i + 1)
          if (rest ~ /^[[:space:]]*$/ || rest ~ /^[[:space:]]+#/) return out
        }
        sub(/[[:space:]]+$/, "", v)
        return v
      }
      if (substr(v, 1, 1) != "{") sub(/[[:space:]]+#.*$/, "", v)
      sub(/[[:space:]]+$/, "", v)
      return v
    }
    function value(line,   v) { v = line; sub(/^[^:]*:[[:space:]]*/, "", v); return clean(v) }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*-[[:space:]]*name:/ { if (loc != "" && rem != "") print loc "|" rem; loc=""; rem=""; next }
    /^[[:space:]]*location:/ { loc = value($0) }
    /^[[:space:]]*remote:/   { rem = value($0) }
    END { if (loc != "" && rem != "") print loc "|" rem }
  ' "$REG")
else
  echo "No registries/repos.yml — skipping clone step."
fi

echo "Done. Open this folder in your agent; it will discover the context via the pointers."
if [ "$missing" -gt 0 ]; then
  echo
  echo "$missing repo(s) above did not arrive. The workspace itself is complete — fix the remote"
  echo "or the location in registries/repos.yml, or clone the repo yourself, then re-run this"
  echo "script to pick it up."
fi
