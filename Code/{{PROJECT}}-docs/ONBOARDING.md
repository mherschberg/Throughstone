# New Contributor Onboarding

This guide is for a new human or agent contributor joining an existing, initialized
Throughstone project. It gives the contributor's first end-to-end path: assemble the
workspace, read the project state from disk, and start their first contribution STEP without
guessing.

This is not the first project bootstrap. The first maintainer ran `./init.sh` from the
Throughstone scaffold to create the project. Later contributors use the generated project
workspace and, for multi-repo projects, `Code/<project>-docs/scripts/setup-workspace.sh`.

## 1. Identify the project shape

Most Throughstone projects are **multi-repo**:

- The workspace root is a per-machine shell, not a repo.
- The docs hub lives at `Code/<project>-docs/`.
- The prompt/history repo lives at `prompts/`.
- Code repos live as siblings under `Code/<project>-*`.

Some early projects are **mono-repo-for-now**:

- There is one repo.
- `AGENTS.md`, `CLAUDE.md`, and `doctor.sh` are committed in that repo.
- `setup-workspace.sh` is not needed. Clone the repo, open it, and continue at
  [Read the project state](#3-read-the-project-state).

## 2. Set up a multi-repo workspace

Create or choose the workspace root, then clone the docs hub into the expected location:

```sh
git clone <docs-repo-url> Code/<project>-docs
```

From the workspace root, run the generated setup helper:

```sh
Code/<project>-docs/scripts/setup-workspace.sh
```

The helper clones sibling repos listed in `Code/<project>-docs/registries/repos.yml` when
they have remotes, then writes the per-machine root files. Verify these exist at the
workspace root:

- `AGENTS.md`
- `CLAUDE.md`
- `doctor.sh`

If a sibling repo has no remote in `registries/repos.yml`, `setup-workspace.sh` cannot clone
it. Read its registry entry and ask the maintainer how that repo is provided.

## 3. Read the project state

Start with these files, in this order:

1. `AGENTS.md` - agent and contributor operating context, including kickoff versus resume.
2. `Code/<project>-docs/METHOD.md` - the method, read once before working.
3. `Code/<project>-docs/overview.md` - project brief and bootstrap status marker.
4. `prompts/STEP-index.md` - roadmap, STEP status, owners, and repo projections.
5. `Code/<project>-docs/registries/repos.yml` - canonical repo inventory.

Then run the local checks from the workspace root:

```sh
./doctor.sh status
./doctor.sh check
./doctor.sh links
```

Use `./doctor.sh status` as the source of the next action. It reads the project state from
disk and applies the next-action resolver from `METHOD.md`. Confirm its result against
`prompts/STEP-index.md`, and if a STEP is already in progress, read its PLAN in
`Upcoming Prompts/`.

## 4. Start your first contribution STEP

Before editing code or durable docs:

1. Read the README for every repo you expect to touch. The repo README is the local setup and
   "about" document for that repo.
2. Read `prompts/STEP-index.md` and select the next appropriate STEP. If you are adding an
   ad-hoc STEP, reserve a number according to `Code/<project>-docs/runbooks/collaboration.md`.
3. Check the selected STEP's `Repos (projection)` against other in-flight rows. If there is
   overlap, call it out before proceeding.
4. Create a branch named `step-NNNN-short-name`. Use the same branch name in every repo the
   STEP touches.
5. Update only your STEP row in `prompts/STEP-index.md` to `In progress` when you start, and
   push that small status change to the shared trunk.
6. Work from the STEP PLAN in `Upcoming Prompts/`, running the lowest open substep first.
7. Edit shared tables narrowly: your own STEP row, your own ADR/registry row, or the row the
   STEP explicitly owns. Do not re-sort or reformat shared tables as drive-by cleanup.
8. When complete, update the STEP review state, archive the PLAN and substep prompts from
   `Upcoming Prompts/` into the appropriate `prompts/<phase>/step-NNNN/` folder, and mark the
   STEP `Done` in `prompts/STEP-index.md`.

For team and concurrency details, read
[`runbooks/collaboration.md`](runbooks/collaboration.md). That runbook owns the full rules
for reserving STEP numbers, branch naming, shared-file edits, ADR numbering, overlap
warnings, and push races.

## 5. Keep paths straight

This scaffold stores the template at `Code/{{PROJECT}}-docs/ONBOARDING.md`. In an
initialized project, the generated docs hub path is `Code/<project>-docs/ONBOARDING.md`.
When editing template files, keep the literal `{{PROJECT}}` placeholder. When instructing
contributors in generated projects, use `Code/<project>-docs`.
