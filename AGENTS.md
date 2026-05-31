# AGENTS.md

The canonical agent context lives in the docs repo:
**`Code/{{PROJECT}}-docs/AGENTS.md`** (tool-agnostic). Read it — and the methodology it
points to in `Code/{{PROJECT}}-docs/METHOD.md` — before working here.

This is a per-machine pointer so any agent (Codex, etc.) auto-discovers the project
context. It is not versioned (the workspace root is not a repo). Edit the canonical file in
the docs repo, not this one. `Code/{{PROJECT}}-docs/scripts/setup-workspace.sh` regenerates
this pointer on a new machine.

**Agents:** the canonical `AGENTS.md` (linked above) opens with a "First action — kickoff or
resume?" section. Read it and follow it now — it decides, from disk, whether to start the
kickoff interview (new project) or resume the next STEP (existing one). The user's whole
handoff is the single command *"Read AGENTS.md and follow it."*
