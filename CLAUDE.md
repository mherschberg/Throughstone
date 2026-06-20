# CLAUDE.md

<!-- THROUGHSTONE-TEMPLATE-GUARD:BEGIN -->
## Template-checkout guard

If the docs path below still contains an unresolved `PROJECT` placeholder in braces, this
checkout is the **Throughstone scaffold before project initialization**, not an initialized
app/project workspace. In that mode, do **not** start the generated-project kickoff/resume
flow. Treat the files under the template docs path as templates for future projects, and
work on the scaffold repo like a normal repository unless the user explicitly asks to run
`./init.sh` or to simulate/test a generated project.

If the docs path below is a concrete project path such as `Code/<name>-docs/AGENTS.md`,
ignore this guard and follow the normal handoff below.
<!-- THROUGHSTONE-TEMPLATE-GUARD:END -->

The canonical agent context lives in the docs repo:
**`Code/{{PROJECT}}-docs/AGENTS.md`** (tool-agnostic). Read it — and the methodology it
points to in `Code/{{PROJECT}}-docs/METHOD.md` — before working here.

This is a per-machine pointer so Claude Code auto-discovers the project context. It is not
versioned (the workspace root is not a repo). Edit the canonical file in the docs repo,
not this one. `Code/{{PROJECT}}-docs/scripts/setup-workspace.sh` regenerates this pointer
on a new machine.

**Agents:** the canonical `AGENTS.md` (linked above) opens with a "First action — kickoff or
resume?" section. Read it and follow it now — it decides, from disk, whether to start the
kickoff interview (new project) or resume the next STEP (existing one). The user's whole
handoff is the single command *"Read AGENTS.md and follow it."*
