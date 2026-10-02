# CLAUDE.md

<!-- THROUGHSTONE-TEMPLATE-GUARD:BEGIN -->
## For Throughstone's authors

First run `git config --get throughstone.author`. If it prints `true`, this checkout is for
working on Throughstone itself. Work on it like a normal repository and do not start the
kickoff. Run `./init.sh` only in a throwaway copy, never here: it turns whatever checkout it
runs in into a generated project. Changes follow `CONTRIBUTING.md`, including its rule that
comments and docs describe the present.

Otherwise skip this section and follow the handoff below.
<!-- THROUGHSTONE-TEMPLATE-GUARD:END -->

The canonical agent context lives in the docs hub:
**`Code/{{PROJECT}}-docs/AGENTS.md`** (tool-agnostic). Read it — and the methodology it
points to in `Code/{{PROJECT}}-docs/METHOD.md` — before working here.

This is a pointer so Claude Code auto-discovers the project context. Edit the canonical file
in the docs hub, not this one. In a multi-repo project the workspace root is not a repo, so
this pointer is not versioned and `Code/{{PROJECT}}-docs/scripts/setup-workspace.sh`
regenerates it on a new machine; in mono-repo-for-now it is committed in the root repo.

**Agents:** the canonical `AGENTS.md` (linked above) opens with a "First action — kickoff or
resume?" section. Read it and follow it now — it decides, from disk, whether to start the
kickoff interview (new project) or resume the next STEP (existing one). The user's whole
handoff is the single command *"Read AGENTS.md and follow it."*
